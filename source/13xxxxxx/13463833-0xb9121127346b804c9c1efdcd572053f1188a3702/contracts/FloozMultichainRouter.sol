pragma solidity =0.6.6;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/LibBytesV06.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/PancakeLibrary.sol";
import "./interfaces/IReferralRegistry.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IZerox.sol";

contract TestMultichainRouter is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using LibBytesV06 for bytes;

    event SwapFeeUpdated(uint16 swapFee);
    event ReferralRegistryUpdated(address referralRegistry);
    event ReferralRewardRateUpdated(uint16 referralRewardRate);
    event ReferralsActivatedUpdated(bool activated);
    event FeeReceiverUpdated(address payable feeReceiver);
    event CustomReferralRewardRateUpdated(address indexed account, uint16 referralRate);
    event ReferralRewardPaid(address from, address indexed to, address tokenOut, address tokenReward, uint256 amount);
    event ForkCreated(address factory);
    event ForkUpdated(address factory);

    struct SwapData {
        address fork;
        address referee;
        bool fee;
    }

    // Denominator of fee
    uint256 public constant FEE_DENOMINATOR = 10000;

    // Numerator of fee
    uint16 public swapFee;

    // address of WETH
    address public immutable WETH;

    // address of zeroEx proxy contract to forward swaps
    address payable public immutable zeroEx;

    // address of referral registry that stores referral anchors
    IReferralRegistry public referralRegistry;

    // address that receives protocol fees
    address payable public feeReceiver;

    // percentage of fees that will be paid as rewards
    uint16 public referralRewardRate;

    // stores if the referral system is turned on or off
    bool public referralsActivated;

    // stores individual referral rates
    mapping(address => uint16) public customReferralRewardRate;

    // stores uniswap forks status, index is the factory address
    mapping(address => bool) public forkActivated;

    // stores uniswap forks initCodes, index is the factory address
    mapping(address => bytes) public forkInitCode;

    /// @dev construct this contract
    /// @param _WETH address of WETH.
    /// @param _swapFee nominator for swapFee. Denominator = 10000
    /// @param _referralRewardRate percentage of swapFee that are paid out as rewards
    /// @param _feeReceiver address that receives protocol fees
    /// @param _referralRegistry address of referral registry that stores referral anchors
    /// @param _zeroEx address of zeroX proxy contract to forward swaps
    constructor(
        address _WETH,
        uint16 _swapFee,
        uint16 _referralRewardRate,
        address payable _feeReceiver,
        IReferralRegistry _referralRegistry,
        address payable _zeroEx
    ) public {
        WETH = _WETH;
        swapFee = _swapFee;
        referralRewardRate = _referralRewardRate;
        feeReceiver = _feeReceiver;
        referralRegistry = _referralRegistry;
        zeroEx = _zeroEx;
        referralsActivated = true;
    }

    /// @dev execute swap directly on Uniswap/Pancake & simular forks
    /// @param swapData stores the swapData information
    /// @param amountOutMin minimum tokens to receive
    /// @param path Sell path.
    /// @return amounts
    function swapExactETHForTokens(
        SwapData calldata swapData,
        uint256 amountOutMin,
        address[] calldata path
    )
        external
        payable
        whenNotPaused
        isValidFork(swapData.fork)
        isValidReferee(swapData.referee)
        returns (uint256[] memory amounts)
    {
        require(path[0] == WETH, "FloozRouter: INVALID_PATH");
        address referee = _getReferee(swapData.referee);
        (uint256 swapAmount, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
            swapData.fee,
            msg.value,
            referee,
            false
        );
        amounts = _getAmountsOut(swapData.fork, swapAmount, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "FloozRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(_pairFor(swapData.fork, path[0], path[1]), amounts[0]));
        _swap(swapData.fork, amounts, path, msg.sender);

        if (feeAmount.add(referralReward) > 0)
            _withdrawFeesAndRewards(address(0), path[path.length - 1], referee, feeAmount, referralReward);
    }

    /// @dev execute swap directly on Uniswap/Pancake/...
    /// @param swapData stores the swapData information
    /// @param amountIn amount of tokensIn
    /// @param amountOutMin minimum tokens to receive
    /// @param path Sell path.
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        SwapData calldata swapData,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    ) external whenNotPaused isValidFork(swapData.fork) isValidReferee(swapData.referee) {
        require(path[path.length - 1] == WETH, "FloozRouter: INVALID_PATH");
        address referee = _getReferee(swapData.referee);
        TransferHelper.safeTransferFrom(path[0], msg.sender, _pairFor(swapData.fork, path[0], path[1]), amountIn);
        _swapSupportingFeeOnTransferTokens(swapData.fork, path, address(this));
        uint256 amountOut = IERC20(WETH).balanceOf(address(this));
        IWETH(WETH).withdraw(amountOut);
        (uint256 amountWithdraw, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
            swapData.fee,
            amountOut,
            referee,
            false
        );
        require(amountWithdraw >= amountOutMin, "FloozRouter: LOW_SLIPPAGE");
        TransferHelper.safeTransferETH(msg.sender, amountWithdraw);

        if (feeAmount.add(referralReward) > 0)
            _withdrawFeesAndRewards(address(0), path[path.length - 1], referee, feeAmount, referralReward);
    }

    /// @dev execute swap directly on Uniswap/Pancake/...
    /// @param swapData stores the swapData information
    /// @param amountIn amount if tokens In
    /// @param amountOutMin minimum tokens to receive
    /// @param path Sell path.
    /// @return amounts
    function swapExactTokensForTokens(
        SwapData calldata swapData,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    )
        external
        whenNotPaused
        isValidFork(swapData.fork)
        isValidReferee(swapData.referee)
        returns (uint256[] memory amounts)
    {
        address referee = _getReferee(swapData.referee);
        (uint256 swapAmount, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
            swapData.fee,
            amountIn,
            referee,
            false
        );
        amounts = _getAmountsOut(swapData.fork, swapAmount, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "FloozRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[0], msg.sender, _pairFor(swapData.fork, path[0], path[1]), swapAmount);
        _swap(swapData.fork, amounts, path, msg.sender);

        if (feeAmount.add(referralReward) > 0)
            _withdrawFeesAndRewards(path[0], path[path.length - 1], referee, feeAmount, referralReward);
    }

    /// @dev execute swap directly on Uniswap/Pancake/...
    /// @param swapData stores the swapData information
    /// @param amountIn amount if tokens In
    /// @param amountOutMin minimum tokens to receive
    /// @param path Sell path.
    /// @return amounts
    function swapExactTokensForETH(
        SwapData calldata swapData,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    )
        external
        whenNotPaused
        isValidFork(swapData.fork)
        isValidReferee(swapData.referee)
        returns (uint256[] memory amounts)
    {
        require(path[path.length - 1] == WETH, "FloozRouter: INVALID_PATH");
        address referee = _getReferee(swapData.referee);
        amounts = _getAmountsOut(swapData.fork, amountIn, path);
        (uint256 amountWithdraw, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
            swapData.fee,
            amounts[amounts.length - 1],
            referee,
            false
        );
        require(amountWithdraw >= amountOutMin, "FloozRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[0], msg.sender, _pairFor(swapData.fork, path[0], path[1]), amounts[0]);
        _swap(swapData.fork, amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(msg.sender, amountWithdraw);

        if (feeAmount.add(referralReward) > 0)
            _withdrawFeesAndRewards(address(0), path[path.length - 1], referee, feeAmount, referralReward);
    }

    /// @dev execute swap directly on Uniswap/Pancake/...
    /// @param swapData stores the swapData information
    /// @param amountOut expected amount of tokens out
    /// @param path Sell path.
    /// @return amounts
    function swapETHForExactTokens(
        SwapData calldata swapData,
        uint256 amountOut,
        address[] calldata path
    )
        external
        payable
        whenNotPaused
        isValidFork(swapData.fork)
        isValidReferee(swapData.referee)
        returns (uint256[] memory amounts)
    {
        require(path[0] == WETH, "FloozRouter: INVALID_PATH");
        address referee = _getReferee(swapData.referee);
        amounts = _getAmountsIn(swapData.fork, amountOut, path);
        (, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
            swapData.fee,
            amounts[0],
            referee,
            true
        );
        require(amounts[0].add(feeAmount).add(referralReward) <= msg.value, "FloozRouter: EXCESSIVE_INPUT_AMOUNT");

        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(_pairFor(swapData.fork, path[0], path[1]), amounts[0]));
        _swap(swapData.fork, amounts, path, msg.sender);

        if (feeAmount.add(referralReward) > 0)
            _withdrawFeesAndRewards(address(0), path[path.length - 1], referee, feeAmount, referralReward);

        // refund dust eth, if any
        if (msg.value > amounts[0].add(feeAmount).add(referralReward))
            TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0].add(feeAmount).add(referralReward));
    }

    /// @dev execute swap directly on Uniswap/Pancake/...
    /// @param swapData stores the swapData information
    /// @param amountIn amount if tokens In
    /// @param amountOutMin minimum tokens to receive
    /// @param path Sell path.
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        SwapData calldata swapData,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    ) external whenNotPaused isValidFork(swapData.fork) isValidReferee(swapData.referee) {
        address referee = _getReferee(swapData.referee);
        (uint256 swapAmount, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
            swapData.fee,
            amountIn,
            referee,
            false
        );
        TransferHelper.safeTransferFrom(path[0], msg.sender, _pairFor(swapData.fork, path[0], path[1]), swapAmount);
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(msg.sender);
        _swapSupportingFeeOnTransferTokens(swapData.fork, path, msg.sender);
        require(
            IERC20(path[path.length - 1]).balanceOf(msg.sender).sub(balanceBefore) >= amountOutMin,
            "FloozRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );

        if (feeAmount.add(referralReward) > 0)
            _withdrawFeesAndRewards(path[0], path[path.length - 1], referee, feeAmount, referralReward);
    }

    /// @dev execute swap directly on Uniswap/Pancake/...
    /// @param swapData stores the swapData information
    /// @param amountOut expected tokens to receive
    /// @param amountInMax maximum tokens to send
    /// @param path Sell path.
    /// @return amounts
    function swapTokensForExactTokens(
        SwapData calldata swapData,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path
    )
        external
        whenNotPaused
        isValidFork(swapData.fork)
        isValidReferee(swapData.referee)
        returns (uint256[] memory amounts)
    {
        address referee = _getReferee(swapData.referee);
        amounts = _getAmountsIn(swapData.fork, amountOut, path);
        (, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
            swapData.fee,
            amounts[0],
            referee,
            true
        );

        require(amounts[0].add(feeAmount).add(referralReward) <= amountInMax, "FloozRouter: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[0], msg.sender, _pairFor(swapData.fork, path[0], path[1]), amounts[0]);
        _swap(swapData.fork, amounts, path, msg.sender);

        if (feeAmount.add(referralReward) > 0)
            _withdrawFeesAndRewards(path[0], path[path.length - 1], referee, feeAmount, referralReward);
    }

    /// @dev execute swap directly on Uniswap/Pancake/...
    /// @param swapData stores the swapData information
    /// @param amountOut expected tokens to receive
    /// @param amountInMax maximum tokens to send
    /// @param path Sell path.
    /// @return amounts
    function swapTokensForExactETH(
        SwapData calldata swapData,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path
    )
        external
        whenNotPaused
        isValidFork(swapData.fork)
        isValidReferee(swapData.referee)
        returns (uint256[] memory amounts)
    {
        require(path[path.length - 1] == WETH, "FloozRouter: INVALID_PATH");
        address referee = _getReferee(swapData.referee);

        (, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
            swapData.fee,
            amountOut,
            referee,
            true
        );

        amounts = _getAmountsIn(swapData.fork, amountOut.add(feeAmount).add(referralReward), path);
        require(amounts[0].add(feeAmount).add(referralReward) <= amountInMax, "FloozRouter: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[0], msg.sender, _pairFor(swapData.fork, path[0], path[1]), amounts[0]);
        _swap(swapData.fork, amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);

        TransferHelper.safeTransferETH(msg.sender, amountOut);
        if (feeAmount.add(referralReward) > 0)
            _withdrawFeesAndRewards(address(0), path[path.length - 1], referee, feeAmount, referralReward);
    }

    /// @dev execute swap directly on Uniswap/Pancake/...
    /// @param swapData stores the swapData information
    /// @param amountOutMin minimum expected tokens to receive
    /// @param path Sell path.
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        SwapData calldata swapData,
        uint256 amountOutMin,
        address[] calldata path
    ) external payable whenNotPaused isValidFork(swapData.fork) isValidReferee(swapData.referee) {
        require(path[0] == WETH, "FloozRouter: INVALID_PATH");
        address referee = _getReferee(swapData.referee);
        (uint256 swapAmount, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
            swapData.fee,
            msg.value,
            referee,
            false
        );
        IWETH(WETH).deposit{value: swapAmount}();
        assert(IWETH(WETH).transfer(_pairFor(swapData.fork, path[0], path[1]), swapAmount));
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(msg.sender);
        _swapSupportingFeeOnTransferTokens(swapData.fork, path, msg.sender);
        require(
            IERC20(path[path.length - 1]).balanceOf(msg.sender).sub(balanceBefore) >= amountOutMin,
            "FloozRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        if (feeAmount.add(referralReward) > 0)
            _withdrawFeesAndRewards(address(0), path[path.length - 1], referee, feeAmount, referralReward);
    }

    /// @dev returns the referee for a given address, if new, registers referee
    /// @param referee the address of the referee for msg.sender
    /// @return referee address from referral registry
    function _getReferee(address referee) internal returns (address) {
        address sender = msg.sender;
        if (!referralRegistry.hasUserReferee(sender) && referee != address(0)) {
            referralRegistry.createReferralAnchor(sender, referee);
        }
        return referralRegistry.getUserReferee(sender);
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(
        address fork,
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = PancakeLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2 ? _pairFor(fork, output, path[i + 2]) : _to;
            IPancakePair(_pairFor(fork, input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(
        address fork,
        address[] memory path,
        address _to
    ) internal {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = PancakeLibrary.sortTokens(input, output);
            IPancakePair pair = IPancakePair(_pairFor(fork, input, output));
            uint256 amountInput;
            uint256 amountOutput;
            {
                // scope to avoid stack too deep errors
                (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
                (uint256 reserveInput, uint256 reserveOutput) = input == token0
                    ? (reserve0, reserve1)
                    : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
                amountOutput = _getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOutput)
                : (amountOutput, uint256(0));
            address to = i < path.length - 2 ? _pairFor(fork, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    /// @dev Fallback function to execute swaps directly on 0x for users that don't pay a fee
    /// @dev params as of API documentation from 0x API (https://0x.org/docs/api#response-1)
    fallback() external payable {
        bytes4 selector = msg.data.readBytes4(0);
        address impl = IZerox(zeroEx).getFunctionImplementation(selector);
        require(impl != address(0), "FloozRouter: NO_IMPLEMENTATION");

        (bool success, ) = impl.delegatecall(msg.data);
        require(success, "FloozRouter: REVERTED");
    }

    /// @dev Executes a swap on 0x API
    /// @param data calldata expected by data field on 0x API (https://0x.org/docs/api#response-1)
    /// @param tokenOut the address of currency to sell - 0x address for ETH
    /// @param tokenIn the address of currency to buy - 0x address for ETH
    /// @param referee address of referee for msg.sender, 0x adress if none
    /// @param fee boolean if fee should be applied or not
    function executeZeroExSwap(
        bytes calldata data,
        address tokenOut,
        address tokenIn,
        address referee,
        bool fee
    ) external payable nonReentrant whenNotPaused isValidReferee(referee) {
        referee = _getReferee(referee);
        bytes4 selector = data.readBytes4(0);
        address impl = IZerox(zeroEx).getFunctionImplementation(selector);
        require(impl != address(0), "FloozRouter: NO_IMPLEMENTATION");

        if (!fee) {
            (bool success, ) = impl.delegatecall(data);
            require(success, "FloozRouter: REVERTED");
        } else {
            // if ETH in execute trade as router & distribute funds & fees
            if (msg.value > 0) {
                (uint256 swapAmount, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
                    fee,
                    msg.value,
                    referee,
                    false
                );
                _withdrawFeesAndRewards(address(0), tokenIn, referee, feeAmount, referralReward);
                (bool success, ) = impl.call{value: swapAmount}(data);
                require(success, "FloozRouter: REVERTED");
                TransferHelper.safeTransfer(tokenIn, msg.sender, IERC20(tokenIn).balanceOf(address(this)));
            } else {
                uint256 balanceBefore = IERC20(tokenOut).balanceOf(msg.sender);
                (bool success, ) = impl.delegatecall(data);
                require(success, "FloozRouter: REVERTED");
                uint256 balanceAfter = IERC20(tokenOut).balanceOf(msg.sender);
                require(balanceBefore > balanceAfter, "INVALID_TOKEN");
                (, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
                    fee,
                    balanceBefore.sub(balanceAfter),
                    referee,
                    true
                );
                _withdrawFeesAndRewards(tokenOut, tokenIn, referee, feeAmount, referralReward);
            }
        }
    }

    /// @dev calculates swap, fee & reward amounts
    /// @param fee boolean if fee will be applied or not
    /// @param amount total amount of tokens
    /// @param referee the address of the referee for msg.sender
    function _calculateFeesAndRewards(
        bool fee,
        uint256 amount,
        address referee,
        bool additiveFee
    )
        internal
        view
        returns (
            uint256 swapAmount,
            uint256 feeAmount,
            uint256 referralReward
        )
    {
        // no fees for users above threshold
        if (!fee) {
            swapAmount = amount;
        } else {
            if (additiveFee) {
                swapAmount = amount;
                feeAmount = swapAmount.mul(FEE_DENOMINATOR).div(FEE_DENOMINATOR.sub(swapFee)).sub(amount);
            } else {
                feeAmount = amount.mul(swapFee).div(FEE_DENOMINATOR);
                swapAmount = amount.sub(feeAmount);
            }

            // calculate referral rates, if referee is not 0x
            if (referee != address(0) && referralsActivated) {
                uint16 referralRate = customReferralRewardRate[referee] > 0
                    ? customReferralRewardRate[referee]
                    : referralRewardRate;
                referralReward = feeAmount.mul(referralRate).div(FEE_DENOMINATOR);
                feeAmount = feeAmount.sub(referralReward);
            } else {
                referralReward = 0;
            }
        }
    }

    /// @dev lets the admin register an Uniswap style fork
    function registerFork(address _factory, bytes calldata _initCode) external onlyOwner {
        require(!forkActivated[_factory], "FloozRouter: ACTIVE_FORK");
        forkActivated[_factory] = true;
        forkInitCode[_factory] = _initCode;
        emit ForkCreated(_factory);
    }

    /// @dev lets the admin update an Uniswap style fork
    function updateFork(
        address _factory,
        bytes calldata _initCode,
        bool _activated
    ) external onlyOwner {
        forkActivated[_factory] = _activated;
        forkInitCode[_factory] = _initCode;
        emit ForkUpdated(_factory);
    }

    /// @dev lets the admin update the swapFee nominator
    function updateSwapFee(uint16 newSwapFee) external onlyOwner {
        swapFee = newSwapFee;
        emit SwapFeeUpdated(newSwapFee);
    }

    /// @dev lets the admin update the referral reward rate
    function updateReferralRewardRate(uint16 newReferralRewardRate) external onlyOwner {
        referralRewardRate = newReferralRewardRate;
        emit ReferralRewardRateUpdated(newReferralRewardRate);
    }

    /// @dev lets the admin update which address receives the protocol fees
    function updateFeeReceiver(address payable newFeeReceiver) external onlyOwner {
        feeReceiver = newFeeReceiver;
        emit FeeReceiverUpdated(newFeeReceiver);
    }

    /// @dev lets the admin update the status of the referral system
    function updateReferralsActivated(bool newReferralsActivated) external onlyOwner {
        referralsActivated = newReferralsActivated;
        emit ReferralsActivatedUpdated(newReferralsActivated);
    }

    /// @dev lets the admin set a new referral registry
    function updateReferralRegistry(address newReferralRegistry) external onlyOwner {
        referralRegistry = IReferralRegistry(newReferralRegistry);
        emit ReferralRegistryUpdated(newReferralRegistry);
    }

    /// @dev lets the admin set a custom referral rate
    function updateCustomReferralRewardRate(address account, uint16 referralRate) external onlyOwner returns (uint256) {
        require(referralRate <= FEE_DENOMINATOR, "FloozRouter: INVALID_RATE");
        customReferralRewardRate[account] = referralRate;
        emit CustomReferralRewardRateUpdated(account, referralRate);
    }

    /// @dev returns the referee for a given user - 0x address if none
    function getUserReferee(address user) external view returns (address) {
        return referralRegistry.getUserReferee(user);
    }

    /// @dev returns if the given user has been referred or not
    function hasUserReferee(address user) external view returns (bool) {
        return referralRegistry.hasUserReferee(user);
    }

    /// @dev lets the admin withdraw ETH from the contract.
    function withdrawETH(address payable to, uint256 amount) external onlyOwner {
        TransferHelper.safeTransferETH(to, amount);
    }

    /// @dev lets the admin withdraw ERC20s from the contract.
    function withdrawERC20Token(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        TransferHelper.safeTransfer(token, to, amount);
    }

    /// @dev distributes fees & referral rewards to users
    function _withdrawFeesAndRewards(
        address tokenReward,
        address tokenOut,
        address referee,
        uint256 feeAmount,
        uint256 referralReward
    ) internal {
        if (tokenReward == address(0)) {
            TransferHelper.safeTransferETH(feeReceiver, feeAmount);
            if (referralReward > 0) {
                TransferHelper.safeTransferETH(referee, referralReward);
                emit ReferralRewardPaid(msg.sender, referee, tokenOut, tokenReward, referralReward);
            }
        } else {
            TransferHelper.safeTransferFrom(tokenReward, msg.sender, feeReceiver, feeAmount);
            if (referralReward > 0) {
                TransferHelper.safeTransferFrom(tokenReward, msg.sender, referee, referralReward);
                emit ReferralRewardPaid(msg.sender, referee, tokenOut, tokenReward, referralReward);
            }
        }
    }

    /// @dev given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "FloozRouter: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "FloozRouter: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn.mul((9975));
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    /// @dev given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function _getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "FloozRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "FloozRouter: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn.mul(amountOut).mul(10000);
        uint256 denominator = reserveOut.sub(amountOut).mul(9975);
        amountIn = (numerator / denominator).add(1);
    }

    /// @dev performs chained getAmountOut calculations on any number of pairs
    function _getAmountsOut(
        address fork,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "FloozRouter: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = _getReserves(fork, path[i], path[i + 1]);
            amounts[i + 1] = _getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    /// @dev performs chained getAmountIn calculations on any number of pairs
    function _getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "FloozRouter: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = _getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = _getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    /// @dev fetches and sorts the reserves for a pair
    function _getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = PancakeLibrary.sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IPancakePair(_pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /// @dev calculates the CREATE2 address for a pair without making any external calls
    function _pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (address pair) {
        (address token0, address token1) = PancakeLibrary.sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        forkInitCode[factory] // init code hash
                    )
                )
            )
        );
    }

    /// @dev lets the admin pause this contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev lets the admin unpause this contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev allows to receive ETH on the contract
    receive() external payable {}

    modifier isValidFork(address factory) {
        require(forkActivated[factory], "FloozRouter: INVALID_FACTORY");
        _;
    }

    modifier isValidReferee(address referee) {
        require(msg.sender != referee, "FloozRouter: SELF_REFERRAL");
        _;
    }
}

