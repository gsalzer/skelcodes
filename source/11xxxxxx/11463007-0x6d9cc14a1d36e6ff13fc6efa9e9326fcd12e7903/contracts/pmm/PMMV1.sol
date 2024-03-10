pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../pmm/0xLibs/LibOrder.sol";
import "../pmm/0xLibs/LibDecoder.sol";
import "../pmm/0xLibs/LibEncoder.sol";
import "../interface/IUserProxyV3.sol";
import "../interface/IZeroExchange.sol";
import "../interface/IWeth.sol";
import "../interface/IPMM.sol";
import "../interface/IPermanentStorageV1.sol";

contract PMMV1 is
    ReentrancyGuard,
    IPMM,
    LibOrder,
    LibDecoder,
    LibEncoder
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* Constants */
    string public constant version = "5.0.0";
    uint256 private constant MAX_UINT = 2**256 - 1;
    string public constant SOURCE = "0x v2";
    uint256 private constant BPS_MAX = 10000;
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable operator;
    IUserProxyV3 public immutable userProxy;
    IPermanentStorageV1 public immutable permStorage;
    IZeroExchange public immutable zeroExchange;
    address public immutable zxERC20Proxy;

    struct TradeInfo {
        address user;
        address receiver;
        uint16 feeFactor;
        address makerAssetAddr;
        address takerAssetAddr;
        bytes32 transactionHash;
        bytes32 orderHash;
    }

    // events
    event FillOrder(
        string source,
        bytes32 indexed transactionHash,
        bytes32 indexed orderHash,
        address indexed userAddr,
        address takerAssetAddr,
        uint256 takerAssetAmount,
        address makerAddr,
        address makerAssetAddr,
        uint256 makerAssetAmount,
        address receiverAddr,
        uint256 settleAmount,
        uint16 feeFactor
    );

    modifier onlyOperator {
        require(operator == msg.sender, "PMM: not operator");
        _;
    }

    modifier onlyUserProxy() {
        require(address(userProxy) == msg.sender, "PMM: not the UserProxy contract");
        _;
    }

    receive() external payable {
    }

    constructor (address _operator, IUserProxyV3 _userProxy, IPermanentStorageV1 _permStorage, IZeroExchange _zeroExchange, address _zxERC20Proxy) public {
        operator = _operator;
        userProxy = _userProxy;
        permStorage = _permStorage;
        zeroExchange = _zeroExchange;
        zxERC20Proxy = _zxERC20Proxy;
        // this const follow ZX_EXCHANGE address
        // encodeTransactionHash depend ZX_EXCHANGE address
        EIP712_DOMAIN_HASH = keccak256(
            abi.encodePacked(
                EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
                keccak256(bytes(EIP712_DOMAIN_NAME)),
                keccak256(bytes(EIP712_DOMAIN_VERSION)),
                bytes12(0),
                address(_zeroExchange)
            )
        );
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

    function _depositToWethIfNeeded(address takerAssetAddr, LibOrder.Order memory order) internal {
        IWETH weth = IWETH(permStorage.wethAddr());
        if (address(weth) == takerAssetAddr) {
            require(
                msg.value == order.takerAssetAmount,
                "PMM: insufficient ETH"
            );
            weth.deposit{value: msg.value}();
        }
    }

    function fill(
        uint256 userSalt,
        bytes memory data,
        bytes memory userSignature
    )
        override
        public
        payable
        onlyUserProxy
        nonReentrant
        returns (uint256)
    {
        // decode & assert
        (LibOrder.Order memory order,
        TradeInfo memory tradeInfo) = _assertTransaction(userSalt, data, userSignature);

        require(permStorage.isValidMM(order.makerAddress), "PMM: not registered market maker");
        userProxy.spendFromUser(tradeInfo.user, tradeInfo.takerAssetAddr, order.takerAssetAmount);
        _depositToWethIfNeeded(tradeInfo.takerAssetAddr, order);

        // saved transaction
        permStorage.setTransactionUser(tradeInfo.transactionHash, tradeInfo.user);
        IERC20(tradeInfo.takerAssetAddr).safeIncreaseAllowance(zxERC20Proxy, order.takerAssetAmount);

        // send tx to 0x
        zeroExchange.executeTransaction(
            userSalt,
            address(this),
            data,
            userSignature
        );

        // settle token/ETH to user
        uint256 settleAmount = _settle(tradeInfo.receiver, tradeInfo.makerAssetAddr, order.makerAssetAmount, tradeInfo.feeFactor);
        IERC20(tradeInfo.takerAssetAddr).safeApprove(zxERC20Proxy, 0);

        emit FillOrder(
            SOURCE,
            tradeInfo.transactionHash,
            tradeInfo.orderHash,
            tradeInfo.user,
            tradeInfo.takerAssetAddr,
            order.takerAssetAmount,
            order.makerAddress,
            tradeInfo.makerAssetAddr,
            order.makerAssetAmount,
            tradeInfo.receiver,
            settleAmount,
            tradeInfo.feeFactor
        );
        return settleAmount;
    }

    // assert & decode transaction
    function _assertTransaction(
        uint256 userSalt,
        bytes memory data,
        bytes memory userSignature
    )
        internal
        view
        returns(
            LibOrder.Order memory order,
            TradeInfo memory tradeInfo
        )
    {
        // decode fillOrder data
        uint256 takerFillAmount;
        bytes memory mmSignature;
        (order, takerFillAmount, mmSignature) = decodeFillOrder(data);

        tradeInfo = TradeInfo(
            address(0),
            address(0),
            0,
            address(0),
            address(0),
            0,
            0
        );

        require(
            order.takerAddress == address(this),
            "PMM: incorrect taker"
        );
        require(
            order.takerAssetAmount == takerFillAmount,
            "PMM: incorrect fill amount"
        );

        // generate transactionHash
        tradeInfo.transactionHash = encodeTransactionHash(
            userSalt,
            address(this),
            data
        );

        // require(
        //     permStorage.getTransactionUser(tradeInfo.transactionHash) == address(0),
        //     "PMM: transaction replayed"
        // );

        tradeInfo.orderHash = getOrderHash(order);

        tradeInfo.feeFactor = uint16(order.salt);
        tradeInfo.receiver = decodeUserSignatureWithoutSign(userSignature);
        tradeInfo.user = _ecrecoverAddress(tradeInfo.transactionHash, userSignature);

        require(
            tradeInfo.user == order.feeRecipientAddress,
            "PMM: maker signed address should be equal to user"
        );

        require(
            tradeInfo.feeFactor < 10000,
            "PMM: invalid fee factor"
        );

        require(
            tradeInfo.receiver != address(0),
            "PMM: invalid receiver"
        );

        // decode asset
        // just support ERC20
        tradeInfo.makerAssetAddr = decodeERC20Asset(order.makerAssetData);
        tradeInfo.takerAssetAddr = decodeERC20Asset(order.takerAssetData);
        return (
            order,
            tradeInfo
        );        
    }

    // settle
    function _settle(address receiver, address makerAssetAddr, uint256 makerAssetAmount, uint16 feeFactor) internal returns(uint256) {
        uint256 settleAmount = makerAssetAmount;
        if (feeFactor > 0) {
            // settleAmount = settleAmount * (10000 - feeFactor) / 10000
            settleAmount = settleAmount.mul((BPS_MAX).sub(feeFactor)).div(BPS_MAX);
        }

        IWETH weth = IWETH(permStorage.wethAddr());
        if (makerAssetAddr == address(weth)){
            weth.withdraw(settleAmount);
            payable(receiver).transfer(settleAmount);
        } else {
            IERC20(makerAssetAddr).safeTransfer(receiver, settleAmount);
        }

        return settleAmount;
    }

    function isValidSignature(bytes32 transactionHash, bytes memory signature) external pure returns (bytes32){
        // User signature is already verified in `fill`, skip validation
        return keccak256("isValidWalletSignature(bytes32,address,bytes)");
    }

    function _ecrecoverAddress(bytes32 transactionHash, bytes memory signature) internal pure returns (address){
        (uint8 v, bytes32 r, bytes32 s, address receiver) = decodeUserSignature(signature);
        return ecrecover(
            keccak256(
                abi.encodePacked(
                    transactionHash,
                    receiver
                )),
            v, r, s
        );
    }
}
