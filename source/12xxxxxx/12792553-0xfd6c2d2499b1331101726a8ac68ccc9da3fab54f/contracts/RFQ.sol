pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/ISpender.sol";
import "./interfaces/IWeth.sol";
import "./interfaces/IRFQ.sol";
import "./interfaces/IPermanentStorage.sol";
import "./interfaces/IERC1271Wallet.sol";
import "./utils/RFQLibEIP712.sol";

contract RFQ is
    ReentrancyGuard,
    IRFQ,
    RFQLibEIP712,
    SignatureValidator
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    // Constants do not have storage slot.
    string public constant version = "5.2.0";
    uint256 private constant MAX_UINT = 2**256 - 1;
    string public constant SOURCE = "RFQ v1";
    uint256 private constant BPS_MAX = 10000;
    address public immutable userProxy;
    IPermanentStorage public immutable permStorage;
    IWETH public immutable weth;

    // Below are the variables which consume storage slots.
    address public operator;
    ISpender public spender;

    struct GroupedVars {
        bytes32 orderHash;
        bytes32 transactionHash;
    }

    // Operator events
    event TransferOwnership(address newOperator);
    event UpgradeSpender(address newSpender);
    event AllowTransfer(address spender);
    event DisallowTransfer(address spender);
    event DepositETH(uint256 ethBalance);

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


    receive() external payable {}


    /************************************************************
    *          Access control and ownership management          *
    *************************************************************/
    modifier onlyOperator {
        require(operator == msg.sender, "RFQ: not operator");
        _;
    }

    modifier onlyUserProxy() {
        require(address(userProxy) == msg.sender, "RFQ: not the UserProxy contract");
        _;
    }

    function transferOwnership(address _newOperator) external onlyOperator {
        require(_newOperator != address(0), "RFQ: operator can not be zero address");
        operator = _newOperator;

        emit TransferOwnership(_newOperator);
    }


    /************************************************************
    *              Constructor and init functions               *
    *************************************************************/
    constructor (
        address _operator, 
        address _userProxy, 
        ISpender _spender, 
        IPermanentStorage _permStorage, 
        IWETH _weth
    ) public {
        operator = _operator;
        userProxy = _userProxy;
        spender = _spender;
        permStorage = _permStorage;
        weth = _weth;
    }


    /************************************************************
    *           Management functions for Operator               *
    *************************************************************/
    /**
     * @dev set new Spender
     */
    function upgradeSpender(address _newSpender) external onlyOperator {
        require(_newSpender != address(0), "RFQ: spender can not be zero address");
        spender = ISpender(_newSpender);

        emit UpgradeSpender(_newSpender);
    }

    /**
     * @dev approve spender to transfer tokens from this contract. This is used to collect fee.
     */
    function setAllowance(address[] calldata _tokenList, address _spender) override external onlyOperator {
        for (uint256 i = 0 ; i < _tokenList.length; i++) {
            IERC20(_tokenList[i]).safeApprove(_spender, MAX_UINT);

            emit AllowTransfer(_spender);
        }
    }

    function closeAllowance(address[] calldata _tokenList, address _spender) override external onlyOperator {
        for (uint256 i = 0 ; i < _tokenList.length; i++) {
            IERC20(_tokenList[i]).safeApprove(_spender, 0);

            emit DisallowTransfer(_spender);
        }
    }

    /**
     * @dev convert collected ETH to WETH
     */
    function depositETH() external onlyOperator {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            weth.deposit{value: balance}();

            emit DepositETH(balance);
        }
    }


    /************************************************************
    *                   External functions                      *
    *************************************************************/
    function fill(
        RFQLibEIP712.Order memory _order,
        bytes memory _mmSignature,
        bytes memory _userSignature
    )
        override
        payable
        external
        nonReentrant
        onlyUserProxy
        returns (uint256)
    {
        // check the order deadline and fee factor
        require(_order.deadline >= block.timestamp, "RFQ: expired order");
        require(_order.feeFactor < BPS_MAX, "RFQ: invalid fee factor");

        GroupedVars memory vars;

        // Validate signatures
        vars.orderHash = _getOrderHash(_order);
        require(
            isValidSignature(
                _order.makerAddr,
                _getOrderSignDigestFromHash(vars.orderHash),
                bytes(""),
                _mmSignature
            ),
            "RFQ: invalid MM signature"
        );
        vars.transactionHash = _getTransactionHash(_order);
        require(
            isValidSignature(
                _order.takerAddr,
                _getTransactionSignDigestFromHash(vars.transactionHash),
                bytes(""),
                _userSignature
            ),
            "RFQ: invalid user signature"
        );

        // Set transaction as seen, PermanentStorage would throw error if transaction already seen.
        permStorage.setRFQTransactionSeen(vars.transactionHash);

        // Deposit to WETH if taker asset is ETH, else transfer from user
        if (address(weth) == _order.takerAssetAddr) {
            require(
                msg.value == _order.takerAssetAmount,
                "RFQ: insufficient ETH"
            );
            weth.deposit{value: msg.value}();
        } else {
            spender.spendFromUser(_order.takerAddr, _order.takerAssetAddr, _order.takerAssetAmount);
        }
        // Transfer from maker
        spender.spendFromUser(_order.makerAddr, _order.makerAssetAddr, _order.makerAssetAmount);

        // settle token/ETH to user
        return _settle(_order, vars);
    }

    // settle
    function _settle(
        RFQLibEIP712.Order memory _order,
        GroupedVars memory _vars
    ) internal returns(uint256) {
        // Transfer taker asset to maker
        IERC20(_order.takerAssetAddr).safeTransfer(_order.makerAddr, _order.takerAssetAmount);

        // Transfer maker asset to taker, sub fee
        uint256 settleAmount = _order.makerAssetAmount;
        if (_order.feeFactor > 0) {
            // settleAmount = settleAmount * (10000 - feeFactor) / 10000
            settleAmount = settleAmount.mul((BPS_MAX).sub(_order.feeFactor)).div(BPS_MAX);
        }

        // Transfer token/Eth to receiver
        if (_order.makerAssetAddr == address(weth)){
            weth.withdraw(settleAmount);
            payable(_order.receiverAddr).transfer(settleAmount);
        } else {
            IERC20(_order.makerAssetAddr).safeTransfer(_order.receiverAddr, settleAmount);
        }

        emit FillOrder(
            SOURCE,
            _vars.transactionHash,
            _vars.orderHash,
            _order.takerAddr,
            _order.takerAssetAddr,
            _order.takerAssetAmount,
            _order.makerAddr,
            _order.makerAssetAddr,
            _order.makerAssetAmount,
            _order.receiverAddr,
            settleAmount,
            uint16(_order.feeFactor)
        );

        return settleAmount;
    }
}

