// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;
pragma abicoder v2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import {BytesLib} from "../integrations/uniswap/BytesLib.sol";
import {AddressProvider} from "../core/AddressProvider.sol";
import {ContractsRegister} from "../core/ContractsRegister.sol";
import {IWETHGateway} from "../interfaces/IWETHGateway.sol";
import {ICreditManager} from "../interfaces/ICreditManager.sol";
import {ICreditFilter} from "../interfaces/ICreditFilter.sol";
import {ISwapRouter} from "../integrations/uniswap/IUniswapV3.sol";
import {IUniswapV2Router02} from "../integrations/uniswap/IUniswapV2Router02.sol";
import {ICurvePool} from "../integrations/curve/ICurvePool.sol";
import {IYVault} from "../integrations/yearn/IYVault.sol";
import {IWETH} from "../interfaces/external/IWETH.sol";
import {YearnAdapter} from "../adapters/YearnV2.sol";

import {Constants} from "../libraries/helpers/Constants.sol";
import {Errors} from "../libraries/helpers/Errors.sol";


contract LeveragedActions is ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address payable;
    using Address for address;
    using SafeERC20 for IERC20;
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;
    uint256 private constant FEE_SIZE = 3;

    /// @dev Contracts reggister to check that credit manager is registered in Gearbox
    ContractsRegister public immutable contractsRegister;

    /// @dev address of WETH token
    address public wethToken;

    /// @dev WETH Gateway for opening ETH credit account
    IWETHGateway public wethGateway;

    struct LongParameters {
        address creditManager;
        uint256 leverageFactor;
        uint256 swapInterface;
        address swapContract;
        bytes swapCalldata;
        uint256 lpInterface;
        address lpContract;
        uint256 amountOutMin;
    }

    // Emits each time new action is done
    event Action(
        address indexed tokenIn,
        address indexed collateral,
        address indexed asset,
        uint256 amountIn,
        address shortSwapContract,
        address longSwapContract,
        address lpContract,
        uint256 referralCode
    );

    // Contract version
    uint constant public version = 1;

    modifier registeredCreditManagersOnly(address creditManager) {
        require(
            contractsRegister.isCreditManager(creditManager),
            Errors.REGISTERED_CREDIT_ACCOUNT_MANAGERS_ONLY
        );
        _;
    }

    constructor(address _addressProvider) {
        require(
            _addressProvider != address(0),
            Errors.ZERO_ADDRESS_IS_NOT_ALLOWED
        );
        AddressProvider addressProvider = AddressProvider(_addressProvider);
        contractsRegister = ContractsRegister(
            addressProvider.getContractsRegister()
        );
        wethGateway = IWETHGateway(addressProvider.getWETHGateway());
        wethToken = addressProvider.getWethToken();
    }

    /// @dev Opens short position (for example, swap USDC to ETH, open credit account in ETH, then swap all ETH on account  to USDC)
    /// @param router UniswapV2 router to use for exchange
    /// @param amountIn Amount in, if you send ETH as value- it would be taken from msg.value
    /// @param amountOutMin Minimal amount after first swap before opening account
    /// @param path UniswapV2 path for short swap
    /// @param longParams parameters for long operation
    /// @param referralCode referral code, it'll be in Action event and in openCreditAccount also
    function openShortUniV2(
        address router,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        uint256 deadline,
        LongParameters calldata longParams,
        uint256 referralCode
    ) external payable nonReentrant {
        address collateral = ICreditManager(longParams.creditManager)
        .underlyingToken();

        require(path.length > 1, Errors.INCORRECT_PATH_LENGTH);
        require(
            path[path.length - 1] == collateral,
            Errors.LA_TOKEN_OUT_IS_NOT_COLLATERAL
        );

        bytes memory data = abi.encodeWithSelector(
            bytes4(0x38ed1739), // "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
            amountIn,
            amountOutMin,
            path,
            address(this),
            deadline
        ); // M:[LA-5]

        _openShort(
            router,
            path[0],
            amountIn,
            collateral,
            data,
            longParams,
            referralCode
        ); // M:[LA-5]
    }

    /// @dev Opens short position (for example, swap USDC to ETH, open credit account in ETH, then swap all ETH to USDC)
    /// @param router UniswapV3 router  (ISwapRouter) to use for exchange
    /// @param paramsV3 Parameters UniV# exact input for short swap operation
    /// @param referralCode referral code, it'll be in Action event and in openCreditAccount also
    function openShortUniV3(
        address router,
        ISwapRouter.ExactInputParams memory paramsV3,
        LongParameters calldata longParams,
        uint256 referralCode
    ) external payable nonReentrant {
        address collateral = ICreditManager(longParams.creditManager)
        .underlyingToken();

        // Getting initial token from short paremeters
        (address tokenIn, address tokenOut) = _extractTokensUniV3(
            paramsV3.path
        ); // M:[LA-6]

        require(tokenOut == collateral, Errors.LA_TOKEN_OUT_IS_NOT_COLLATERAL);

        // Changes recipient to this contract
        paramsV3.recipient = address(this); // M:[LA-6]

        bytes memory data = abi.encodeWithSelector(
            bytes4(0xc04b8d59), // +
            paramsV3
        ); // M:[LA-6]

        _openShort(
            router,
            tokenIn,
            paramsV3.amountIn,
            collateral,
            data,
            longParams,
            referralCode
        ); // M:[LA-6]
    }

    /// @dev Opens short position (for example, swap USDC to ETH, open credit account in ETH, then swap all ETH to USDC)
    /// @param curvePool Curve pool address
    /// @param i Index value for the coin to send
    /// @param j Index value of the coin to receive
    /// @param amountIn Amount in, if you send ETH as value- it would be taken from msg.value
    /// @param amountOutMin Minimal amount after first swap before opening account
    /// @param longParams parameters for long operation
    /// @param referralCode referral code, it'll be in Action event and in openCreditAccount also
    function openShortCurve(
        address curvePool,
        int128 i,
        int128 j,
        uint256 amountIn,
        uint256 amountOutMin,
        LongParameters calldata longParams,
        uint256 referralCode
    ) external payable nonReentrant {
        address collateral = ICreditManager(longParams.creditManager)
        .underlyingToken();

        address tokenIn = ICurvePool(curvePool).coins(uint256(i)); // M:[LA-1]
        address tokenOut = ICurvePool(curvePool).coins(uint256(j)); // M:[LA-1]

        require(tokenOut == collateral, Errors.LA_TOKEN_OUT_IS_NOT_COLLATERAL);

        bytes memory data = abi.encodeWithSelector(
            bytes4(0x3df02124), //"exchange(int128,int128,uint256,uint256)"
            i,
            j,
            amountIn,
            amountOutMin
        ); // M:[LA-7]

        _openShort(
            curvePool,
            tokenIn,
            amountIn,
            collateral,
            data,
            longParams,
            referralCode
        ); // M:[LA-7]
    }

    /// @dev Opens long position (for example, open credit account in ETH, then swap all ETH to USDC)
    /// @param amountIn Amount in, if you send ETH as value- it would be taken from msg.value
    /// @param longParams parameters for long operation
    /// @param referralCode referral code, it'll be in Action event and in openCreditAccount also
    function openLong(
        uint256 amountIn,
        LongParameters calldata longParams,
        uint256 referralCode
    ) external payable nonReentrant {
        address collateral = ICreditManager(longParams.creditManager)
        .underlyingToken(); // M:[LA-1]

        uint256 balanceBefore = IERC20(collateral).balanceOf(address(this));

        _getTokenOrWrapETH(collateral, amountIn); // M:[LA-1]

        address asset = _openLong(
            IERC20(collateral).balanceOf(address(this)).sub(balanceBefore),
            longParams,
            referralCode
        ); // M:[LA-1]

        emit Action(
            collateral,
            collateral,
            asset,
            amountIn,
            address(0),
            longParams.swapContract,
            longParams.lpContract,
            referralCode
        ); // M:[LA-1]
    }

    /// @dev Opens leveraged account and put all money into LP Contract (Yearn for example)
    function openLP(
        address creditManager,
        uint256 leverageFactor,
        uint256 amountIn,
        uint256 lpInterface,
        address lpContract,
        uint256 amountOutMin,
        uint256 referralCode
    )
        external
        payable
        registeredCreditManagersOnly(creditManager)
        nonReentrant
    {
        // Gets collateral
        address collateral = ICreditManager(creditManager).underlyingToken(); // M:[LA-8]

        uint256 balanceBefore = IERC20(collateral).balanceOf(address(this));
        // Transgers tokens / wraps ETH
        _getTokenOrWrapETH(collateral, amountIn); // M:[LA-8]

        // Provide needed allowance
        _provideCreditAccountAllowance(creditManager, collateral); // M:[LA-8]

        // Opens credit account
        ICreditManager(creditManager).openCreditAccount(
            IERC20(collateral).balanceOf(address(this)).sub(balanceBefore),
            address(this),
            leverageFactor,
            referralCode
        );

        // Deposits LP
        address lpAsset = _depositLP(creditManager, lpInterface, lpContract); // M:[LA-8]

        require(
            IERC20(lpAsset).balanceOf(
                ICreditManager(creditManager).getCreditAccountOrRevert(
                    address(this)
                )
            ) >= amountOutMin,
            Errors.LA_LOWER_THAN_AMOUNT_MIN
        );

        // Transfers ownership to msg.sender
        ICreditManager(creditManager).transferAccountOwnership(msg.sender); // M:[LA-8]

        // Emits actions
        emit Action(
            collateral,
            collateral,
            lpAsset,
            amountIn,
            address(0),
            address(0),
            lpContract,
            referralCode
        ); // M:[LA-8]
    }

    function _openShort(
        address shortSwapContract,
        address tokenIn,
        uint256 amountIn,
        address collateral,
        bytes memory shortSwapCalldata,
        LongParameters calldata longParams,
        uint256 referralCode
    ) internal {
        // Checks that swapContract is allowed
        _getAdapterOrRevert(longParams.creditManager, shortSwapContract); // M:[LA-5, 6, 7]

        // Transfers tokens from msg.sender to contract
        _getTokenOrWrapETH(tokenIn, amountIn); // M:[LA-5, 6, 7]

        uint256 balanceBefore = IERC20(collateral).balanceOf(address(this));
        // Provides enough allowance to swapContract
        _provideCreditAccountAllowance(shortSwapContract, tokenIn); // M:[LA-5, 6, 7]

        // Calls short swap
        shortSwapContract.functionCall(shortSwapCalldata); // M:[LA-5, 6, 7]

        // Opens long position and transfer ownership
        address asset = _openLong(
            IERC20(collateral).balanceOf(address(this)).sub(balanceBefore),
            longParams,
            referralCode
        ); // M:[LA-5, 6, 7]

        // Returns tokens if they exists on this contract
        _returnTokenOrUnwrapWETH(tokenIn); // M:[LA-5, 6, 7]

        // Emits action
        emit Action(
            tokenIn,
            collateral,
            asset,
            amountIn,
            shortSwapContract,
            longParams.swapContract,
            longParams.lpContract,
            referralCode
        ); // M:[LA-5, 6, 7]
    }

    /// @dev Opens position: open account with desired le
    /// - opens account with desired leerage factor
    /// - transfers all assets using provided adapter to desired asset
    /// - executes lp operation, if provided
    function _openLong(
        uint256 amount,
        LongParameters calldata longParams,
        uint256 referralCode
    )
        internal
        registeredCreditManagersOnly(longParams.creditManager)
        returns (address asset)
    {
        address collateral = ICreditManager(longParams.creditManager)
        .underlyingToken(); // M:[LA-1]

        //        uint256 amount = IERC20(collateral).balanceOf(address(this)); // M:[LA-1]

        _provideCreditAccountAllowance(longParams.creditManager, collateral); // M:[LA-1]
        ICreditManager(longParams.creditManager).openCreditAccount(
            amount,
            address(this),
            longParams.leverageFactor,
            referralCode
        ); // M:[LA-1]

        address creditAccount = ICreditManager(longParams.creditManager)
        .getCreditAccountOrRevert(address(this));

        uint256 leveragedAmount = IERC20(collateral).balanceOf(creditAccount); // M:[LA-1]

        address adapter = _getAdapterOrRevert(
            longParams.creditManager,
            longParams.swapContract
        );

        //
        // UNISWAP V2 INTERFACE
        //
        if (longParams.swapInterface == Constants.UNISWAP_V2) {
            (
                uint256 amountIn,
                uint256 amountOutMin,
                address[] memory path,
                ,
                uint256 deadline
            ) = abi.decode(
                longParams.swapCalldata,
                (uint256, uint256, address[], address, uint256)
            ); // M:[LA-1]

            uint256 amountOutMinLeveraged = amountOutMin
            .mul(leveragedAmount)
            .div(amountIn); // M:[LA-1]

            IUniswapV2Router02(adapter).swapExactTokensForTokens(
                leveragedAmount,
                amountOutMinLeveraged,
                path,
                address(this), // it will be replaced in adapter
                deadline
            ); // M:[LA-1]

            require(path[0] == collateral, Errors.INCORRECT_PARAMETER);

            asset = path[path.length - 1]; // M:[LA-1]
        }
        //
        //  UNISWAP V3 INTERFACE
        //
        else if (longParams.swapInterface == Constants.UNISWAP_V3) {
            ISwapRouter.ExactInputParams memory params = abi.decode(
                longParams.swapCalldata,
                (ISwapRouter.ExactInputParams)
            );

            params.amountOutMinimum = params
            .amountOutMinimum
            .mul(leveragedAmount)
            .div(params.amountIn);
            params.amountIn = leveragedAmount;
            ISwapRouter(adapter).exactInput(params);
            (, asset) = _extractTokensUniV3(params.path);
        }
        //
        // CURVE V1 INTERFACE
        //
        else if (longParams.swapInterface == Constants.CURVE_V1) {
            (int128 i, int128 j, uint256 dx, uint256 min_dy) = abi.decode(
                longParams.swapCalldata,
                (int128, int128, uint256, uint256)
            );

            ICurvePool(adapter).exchange(
                i,
                j,
                leveragedAmount,
                min_dy.mul(leveragedAmount).div(dx)
            );
            asset = ICurvePool(longParams.swapContract).coins(uint256(j));
        } else {
            revert(Errors.LA_UNKNOWN_SWAP_INTERFACE); // Todo:
        }

        //
        // LP
        //

        if (longParams.lpContract != address(0)) {
            asset = _depositLP(
                longParams.creditManager,
                longParams.lpInterface,
                longParams.lpContract
            ); // M:[LA-2]
        }

        require(
            IERC20(asset).balanceOf(creditAccount) >= longParams.amountOutMin,
            Errors.LA_LOWER_THAN_AMOUNT_MIN
        );

        ICreditManager(longParams.creditManager).transferAccountOwnership(
            msg.sender
        ); // M:[LA-1, 2, 3, 4]
    }

    /// @dev Opens LP position for whole money on account
    /// @param creditManager Address of creditManager
    /// @param lpInterface LP Interface
    /// @param lpContract Address of LP contract
    /// @return LP asset address
    function _depositLP(
        address creditManager,
        uint256 lpInterface,
        address lpContract
    ) internal returns (address) {
        address lpAdapter = _getAdapterOrRevert(creditManager, lpContract);

        if (lpInterface == Constants.LP_YEARN) {
            IYVault(lpAdapter).deposit(); // M: [LA-2]
            return lpContract;
        }
        revert(Errors.LA_UNKNOWN_LP_INTERFACE);
    }

    /// @dev Transfers money from msg.sender account or convert from eth if
    /// @param token Address on token
    /// @param amountIn Amount of tokens to be transferred. If value is attached to tx, it should be equal amountIn
    function _getTokenOrWrapETH(address token, uint256 amountIn) internal {
        if (token == wethToken && msg.value > 0) {
            require(msg.value == amountIn, Errors.LA_INCORRECT_VALUE); // M:[LA-12]
            IWETH(wethToken).deposit{value: msg.value}(); // M:[LA-2, ]
        } else {
            require(msg.value == 0, Errors.LA_HAS_VALUE_WITH_TOKEN_TRANSFER); // M:[LA-11]
            IERC20(token).safeTransferFrom(msg.sender, address(this), amountIn); // M:[LA-1,3,4,5,6,7,8]
        }
    }

    /// @dev Transfers unused tokens back or ETH if it's wethToken
    /// @param token Address of token
    function _returnTokenOrUnwrapWETH(address token) internal {
        // Checks balanceAfter and returns money if not all tokens were converted
        uint256 balance = IERC20(token).balanceOf(address(this)); //  // M:[LA-13, 14]
        if (balance > 0) {
            if (token == wethToken) {
                IWETH(wethToken).withdraw(balance); // M:[LA-14]
                payable(msg.sender).sendValue(balance); // M:[LA-14]
            } else {
                IERC20(token).safeTransfer(msg.sender, balance); // M:[LA-13]
            }
        }
    }

    /// @dev Returns adapter for provided contract or reverts if it's now allowed
    /// @param creditManager Address of credit manager
    /// @param targetContract Address of contract which adapter is needed
    function _getAdapterOrRevert(address creditManager, address targetContract)
        internal
        view
        returns (address)
    {
        // Could be optimised by adding internal list of creditManagers
        ICreditFilter creditFilter = ICreditFilter(
            ICreditManager(creditManager).creditFilter()
        ); // M:[LA-10]

        address adapter = creditFilter.contractToAdapter(targetContract);
        require(
            adapter != address(0),
            Errors.CF_CONTRACT_IS_NOT_IN_ALLOWED_LIST
        ); // M:[LA-10]
        return adapter;
    }

    /// @dev Extracts from and to tokens from UniV3 path
    /// @param path UniV3 encoded path
    /// @return tokenA tokenIn
    /// @return tokenB tokenOut
    function _extractTokensUniV3(bytes memory path)
        internal
        pure
        returns (address tokenA, address tokenB)
    {
        require(
            path.length >= 2 * ADDR_SIZE + FEE_SIZE,
            Errors.INCORRECT_PATH_LENGTH
        );

        tokenA = path.toAddress(0);
        tokenB = path.toAddress(path.length - ADDR_SIZE);
    }

    /// @dev Checks that credit account has enough allowance for operation by comparing existing one with x10 times more than needed
    /// @param targetContract Contract to check allowance
    /// @param token Token address of contract
    function _provideCreditAccountAllowance(
        address targetContract,
        address token
    ) internal {
        // Get 10x reserve in allowance
        if (
            IERC20(token).allowance(address(this), targetContract) <
            Constants.MAX_INT_4
        ) {
            IERC20(token).safeApprove(targetContract, 0); // M:[LA-1,2,3,4,]
            IERC20(token).safeApprove(targetContract, Constants.MAX_INT); // M:[LA-1,2,3,4]
        }
    }

    function isTransferAllowed(address creditManager)
        external
        view
        returns (bool)
    {
        ICreditFilter creditFilter = ICreditFilter(
            ICreditManager(creditManager).creditFilter()
        );
        return
            creditFilter.allowanceForAccountTransfers(
                address(this),
                msg.sender
            );
    }

    receive() external payable {} // M:[LA-14]
}

