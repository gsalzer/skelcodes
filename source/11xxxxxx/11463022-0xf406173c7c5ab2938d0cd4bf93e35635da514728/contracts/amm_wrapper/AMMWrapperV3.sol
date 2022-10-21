pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interface/IUserProxyV3.sol";
import "../interface/IUniswapExchange.sol";
import "../interface/IUniswapFactory.sol";
import "../interface/IUniswapRouterV2.sol";
import "../interface/ICurveFi.sol";
import "../interface/IAMM.sol";
import "../interface/IWeth.sol";
import "../interface/IPermanentStorageV1.sol";
import "../utils/SignatureValidator.sol";

contract AMMWrapperV3 is
    IAMM,
    ReentrancyGuard,
    SignatureValidator
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* Constants */
    string public constant version = "5.0.0";
    uint256 private constant MAX_UINT = 2**256 - 1;
    uint256 private constant BPS_MAX = 10000;
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant ZERO_ADDRESS = address(0);
    IUserProxyV3 public immutable userProxy;
    IPermanentStorageV1 public immutable permStorage;
    address public immutable UNISWAP_V2_ROUTER_02_ADDRESS;

    /* Storage */
    address public operator;
    uint256 public subsidyFactor;

    /* Struct and event declaration */
    // Group the local variables together to prevent
    // Compiler error: Stack too deep, try removing local variables.
    struct GroupedVars {
        IWETH weth;
        bool fromEth;
        bool toEth;
        bool makerIsUniV2;
        string source;
        bytes32 transactionHash;
        address takerAssetInternalAddr;
        address makerAssetInternalAddr;
        uint256 receivedAmount;
        uint256 settleAmount;

        // Variables used as the copy of the function parameters
        // to bypass stack too deep error when logging event.
        address userAddr;
        address takerAssetAddr;
        uint256 takerAssetAmount;
        address makerAddr;
        address makerAssetAddr;
        uint256 makerAssetAmount;
        address payable receiverAddr;
        uint16 feeFactor;
    }

    event Swapped(
        string source,
        bytes32 indexed transactionHash,
        address indexed userAddr,
        address takerAssetAddr,
        uint256 takerAssetAmount,
        address makerAddr,
        address makerAssetAddr,
        uint256 makerAssetAmount,
        address receiverAddr,
        uint256 settleAmount,
        uint16 feeFactor,
        uint16 subsidyFactor
    );

    modifier onlyOperator() {
        require(operator == msg.sender, "AMMWrapper: not the operator");
        _;
    }

    modifier onlyUserProxy() {
        require(address(userProxy) == msg.sender, "AMMWrapper: not the UserProxy contract");
        _;
    }

    receive() external payable {}

    constructor (address _operator, uint256 _subsidyFactor, IUserProxyV3 _userProxy, IPermanentStorageV1 _permStorage, address _uniswap_v2_router) public {
        operator = _operator;
        subsidyFactor = _subsidyFactor;
        userProxy = _userProxy;
        permStorage = _permStorage;
        UNISWAP_V2_ROUTER_02_ADDRESS = _uniswap_v2_router;
    }

    function transferOwnership(address _newOperator) external onlyOperator {
        require(_newOperator != address(0), "AMMWrapper: operator can not be zero address");
        operator = _newOperator;
    }

    function setSubsidyFactor(uint256 _subsidyFactor) external onlyOperator {
        subsidyFactor = _subsidyFactor;
    }

    function setAllowance(address[] memory tokenList, address spender) override external onlyOperator {
        for (uint256 i = 0 ; i < tokenList.length; i++) {
            IERC20(tokenList[i]).safeApprove(spender, MAX_UINT);
        }
    }

    function closeAllowance(address[] memory tokenList, address spender) override external onlyOperator {
        for (uint256 i = 0 ; i < tokenList.length; i++) {
            IERC20(tokenList[i]).safeApprove(spender, 0);
        }
    }

    function depositETH() external onlyOperator {
        uint256 balance = address(this).balance;
        IWETH weth = IWETH(permStorage.wethAddr());
        if (balance > 0) weth.deposit{value: balance}();
    }

    function _prepare(
        bool fromEth,
        IWETH weth,
        address _makerAddr,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _takerAssetAmount,
        uint256 _makerAssetAmount,
        address _userAddr,
        address _receiverAddr,
        uint256 _nonce,
        uint256 _deadline,
        bytes memory _sig
    ) internal returns (bytes32 transactionHash) {
        // Verify user signature
        // keccak256("tradeWithPermit(address makerAddr,address takerAssetAddr,address makerAssetAddr,uint256 takerAssetAmount,uint256 makerAssetAmount,address receiverAddr,uint256 nonce,uint256 deadline)");
        // Compute `_hash` in two steps to prevent stack too deep error
        transactionHash = keccak256(
            abi.encode(
                TRADE_WITH_PERMIT_TYPEHASH,
                _makerAddr,
                _takerAssetAddr,
                _makerAssetAddr,
                _takerAssetAmount,
                _makerAssetAmount,
                _userAddr,
                _receiverAddr,
                _nonce,
                _deadline
            )
        );
        bytes32 EIP712SignDigest = keccak256(
            abi.encodePacked(
                EIP191_HEADER,
                EIP712_DOMAIN_SEPARATOR,
                transactionHash
            )
        );
        require(isValidSignature(_userAddr, EIP712SignDigest, bytes(""), _sig), "AMMWrapper: invalid user signature");

        // Validate user nonce
        require(permStorage.getNonce(_userAddr) == _nonce, "AMMWrapper: invalid user nonce");
        // Increment user nonce
        permStorage.increNonce(_userAddr);

        // Transfer asset from user and deposit to weth if needed
        if (fromEth) {    
            require(msg.value > 0, "AMMWrapper: msg.value is zero");
            require(_takerAssetAmount == msg.value, "AMMWrapper: msg.value doesn't match");
            // Deposit ETH to weth
            weth.deposit{value: msg.value}();
        } else {
            userProxy.spendFromUser(_userAddr, _takerAssetAddr, _takerAssetAmount);
        }
    }

    function _swap(
        bool makerIsUniV2,
        address _makerAddr,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _takerAssetAmount,
        uint256 _makerAssetAmount,
        uint256 _deadline
    ) internal returns (string memory source, uint256 receivedAmount) {
        // Approve
        IERC20(_takerAssetAddr).safeApprove(_makerAddr, _takerAssetAmount);

        // Swap
        int128 fromTokenCurveIndex = permStorage.getCurveTokenIndex(_makerAddr, _takerAssetAddr);
        int128 toTokenCurveIndex = permStorage.getCurveTokenIndex(_makerAddr, _makerAssetAddr);
        // minAmount = makerAssetAmount * (10000 - subsidyFactor) / 10000
        uint256 minAmount = _makerAssetAmount.mul((BPS_MAX.sub(subsidyFactor))).div(BPS_MAX);
        if (fromTokenCurveIndex != 0 || toTokenCurveIndex != 0) {
            source = "Curve";
            uint256 balanceBeforeTrade = IERC20(_makerAssetAddr).balanceOf(address(this));
            _tradeCurveTokenToToken(_makerAddr, fromTokenCurveIndex, toTokenCurveIndex, _takerAssetAmount, minAmount);
            uint256 balanceAfterTrade = IERC20(_makerAssetAddr).balanceOf(address(this));
            receivedAmount = balanceAfterTrade.sub(balanceBeforeTrade);
        } else if (makerIsUniV2) {
            source = "Uniswap V2";
            receivedAmount = _tradeUniswapV2TokenToToken(_takerAssetAddr, _makerAssetAddr, _takerAssetAmount, minAmount, _deadline);
        } else {
            revert("AMMWrapper: Unsupported makerAddr");
        }

        // Close allowance
        IERC20(_takerAssetAddr).safeApprove(_makerAddr, 0);
    }

    function _settle(
        bool _toEth,
        IWETH weth,
        address _makerAssetAddr,
        uint256 _makerAssetAmount,
        uint256 _receivedAmount,
        uint256 _feeFactor,
        address payable _receiverAddr
    )
        internal
        returns (uint256 settleAmount)
    {
        IERC20 makerAsset;
        if (_toEth) {
            makerAsset = IERC20(address(weth));
        } else {
            makerAsset = IERC20(_makerAssetAddr);
        }

        if (_receivedAmount == _makerAssetAmount) {
            settleAmount = _receivedAmount;
        } else if (_receivedAmount > _makerAssetAmount) {
            // shouldCollectFee = ((receivedAmount - makerAssetAmount) / receivedAmount) > (feeFactor / 10000)
            bool shouldCollectFee = _receivedAmount.sub(_makerAssetAmount).mul(BPS_MAX) > _feeFactor.mul(_receivedAmount);
            if (shouldCollectFee) {
                // settleAmount = receivedAmount * (1 - feeFactor) / 10000
                settleAmount = _receivedAmount.mul(BPS_MAX.sub(_feeFactor)).div(BPS_MAX);
            } else {
                settleAmount = _makerAssetAmount;
            }
        } else {
            // If fee factor is smaller than subsidy factor, choose fee factor as actual subsidy factor
            // since we should subsidize less if we charge less.
            uint256 actualSubsidyFactor = (subsidyFactor < _feeFactor) ? subsidyFactor : _feeFactor;

            // inSubsidyRange = ((makerAssetAmount - receivedAmount) / receivedAmount) > (actualSubsidyFactor / 10000)
            bool inSubsidyRange = _makerAssetAmount.sub(_receivedAmount).mul(BPS_MAX) <= actualSubsidyFactor.mul(_receivedAmount);
            require(inSubsidyRange, "AMMWrapper: amount difference larger than subsidy amount");

            bool hasEnoughToSubsidize = (makerAsset.balanceOf(address(this)) >= _makerAssetAmount);
            require(hasEnoughToSubsidize, "AMMWrapper: not enough savings to subsidize");

            settleAmount = _makerAssetAmount;
        }

        // Transfer token/Eth to receiver
        if (_toEth) {
            weth.withdraw(settleAmount);
            _receiverAddr.transfer(settleAmount);
        } else {
            makerAsset.safeTransfer(_receiverAddr, settleAmount);
        }
    }

    function trade(
        address _makerAddr,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _takerAssetAmount,
        uint256 _makerAssetAmount,
        uint256 _feeFactor,
        address _userAddr,
        address payable _receiverAddr,
        uint256 _nonce,
        uint256 _deadline,
        bytes memory _sig
    )
        override
        payable
        external
        nonReentrant
        onlyUserProxy
        returns (uint256) 
    {
        GroupedVars memory vars;
        vars.weth = IWETH(permStorage.wethAddr());

        // These variables are copied straight from function parameters and
        // used to bypass stack too deep error.
        vars.userAddr = _userAddr;
        vars.takerAssetAddr = _takerAssetAddr;
        vars.takerAssetAmount = _takerAssetAmount;
        vars.makerAddr = _makerAddr;
        vars.makerAssetAddr = _makerAssetAddr;
        vars.makerAssetAmount = _makerAssetAmount;
        vars.receiverAddr = _receiverAddr;
        vars.feeFactor = uint16(_feeFactor);

        // Assign trade vairables
        vars.fromEth = (_takerAssetAddr == ZERO_ADDRESS || _takerAssetAddr == ETH_ADDRESS);
        vars.toEth = (_makerAssetAddr == ZERO_ADDRESS || _makerAssetAddr == ETH_ADDRESS);
        vars.makerIsUniV2 = (_makerAddr == UNISWAP_V2_ROUTER_02_ADDRESS);
        vars.takerAssetInternalAddr = vars.fromEth? address(vars.weth) : _takerAssetAddr;
        vars.makerAssetInternalAddr = vars.toEth ? address(vars.weth) : _makerAssetAddr;

        vars.transactionHash = _prepare(
            vars.fromEth,
            vars.weth,
            vars.makerAddr,
            vars.takerAssetAddr,
            vars.makerAssetAddr,
            vars.takerAssetAmount,
            vars.makerAssetAmount,
            vars.userAddr,
            vars.receiverAddr,
            _nonce,
            _deadline,
            _sig
        );

        (vars.source, vars.receivedAmount) = _swap(
            vars.makerIsUniV2,
            vars.makerAddr,
            vars.takerAssetInternalAddr,
            vars.makerAssetInternalAddr,
            vars.takerAssetAmount,
            vars.makerAssetAmount,
            _deadline
        );

        // Settle
        vars.settleAmount = _settle(
            vars.toEth,
            vars.weth,
            vars.makerAssetAddr,
            vars.makerAssetAmount,
            vars.receivedAmount,
            vars.feeFactor,
            vars.receiverAddr
        );

        emit Swapped(
            vars.source,
            vars.transactionHash,
            vars.userAddr,
            vars.takerAssetAddr,
            vars.takerAssetAmount,
            vars.makerAddr,
            vars.makerAssetAddr,
            vars.makerAssetAmount,
            vars.receiverAddr,
            vars.settleAmount,
            vars.feeFactor,
            uint16(subsidyFactor)
        );

        return vars.settleAmount;
    }

    function _tradeCurveTokenToToken(
        address _makerAddr,
        int128 i,
        int128 j,
        uint256 _takerAssetAmount,
        uint256 _makerAssetAmount
    ) 
        internal 
    {
        ICurveFi curve = ICurveFi(_makerAddr);
        curve.exchange_underlying(i, j, _takerAssetAmount, _makerAssetAmount);
    }

    function _tradeUniswapV2TokenToToken(
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _takerAssetAmount,
        uint256 _makerAssetAmount,
        uint256 _deadline
    ) 
        internal 
        returns (uint256) 
    {
        IUniswapRouterV2 router = IUniswapRouterV2(UNISWAP_V2_ROUTER_02_ADDRESS);
        address[] memory path = new address[](2);
        path[0] = _takerAssetAddr;
        path[1] = _makerAssetAddr;
        uint256[] memory amounts = router.swapExactTokensForTokens(
            _takerAssetAmount,
            _makerAssetAmount,
            path,
            address(this),
            _deadline
        );
        return amounts[1];
    }
}
