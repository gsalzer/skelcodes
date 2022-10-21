// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

import "./SafeMath.sol";
import "./IERC20.sol";

interface UserTrustLists {
    function inTrustLists(address user, address people) external returns (bool);
}

contract Ethc2cWETH {
    using SafeMath for uint256;

    IERC20 WETH;
    IERC20 HAMMER;
    UserTrustLists userTrust;
    address public feeTo;

    constructor(address _WETH, address _HAMMER, address _userTrust, address _feeTo) {
        WETH = IERC20(_WETH);
        HAMMER = IERC20(_HAMMER);
        userTrust = UserTrustLists(_userTrust);
        feeTo = _feeTo;
    }

     /*卖单状态
    卖家发布卖单   SellerCreated
    卖家暂停卖单   SellerSuspend 
    卖家取消卖单   SellerCancelled
    卖单超时赎回   SellerRedeem

    买家提交买单    BuyerSubmit
    买家确认付款    BuyerConfirmPayment

    卖家确认收款   SellerConfirmReceive
    卖家超时未确认 SellerOutofTime
    */
    enum State {SellerCreated,
                SellerSuspend,
                SellerCancelled, 
                SellerRedeem, 
                BuyerSubmit, 
                BuyerConfirmPayment,
                SellerConfirmReceive, 
                SellerOutofTime}
   
    uint256 public id = 0;
    uint256 public orderValidity = 4 hours;
    uint256 public paymentValidity = 2 hours;

    struct OrderMessage
    {
        uint256 orderNumber;
        uint256 amount;
        uint256 price;
        bool    isTrust;
        address seller;
        address buyer;
        uint256 submitTime;
        uint8   numberOfRounds;
        State   state;
    }

    mapping(uint256 => OrderMessage) public orders;
    
    modifier onlySeller(uint256 _uid) {
        require(msg.sender == orders[_uid].seller);
        _;
    }
    
    modifier onlyBuyer(uint256 _uid) {
        require(msg.sender == orders[_uid].buyer);
        _;
    }
    
    modifier inState(uint256 _uid, State _state) {
        require(orders[_uid].state == _state);
        _;
    }
    
    modifier orderInTime(uint256 _uid) {
        require(block.timestamp <= orders[_uid].submitTime + orderValidity);
        _;
    }
    
    modifier orderOutOfTime(uint256 _uid) {
        require(block.timestamp > orders[_uid].submitTime + orderValidity);
        _;
    }

    modifier ConfirmInTime(uint256 _uid) {
        require(block.timestamp <= orders[_uid].submitTime + paymentValidity);
        _;
    }
    
    modifier ConfirmOutOfTime(uint256 _uid) {
        require(block.timestamp > orders[_uid].submitTime + paymentValidity);
        _;
    }

    //事件日志   
    event SetOrder(uint256 indexed orderNumber, address seller, uint256 amount, bool isTrust, uint256 orderCreated);
    event SellerSuspend(uint256 indexed orderNumber, address seller, uint256 amount, uint256 orderSuspend);
    event CancelOrder(uint256 indexed orderNumber, address seller, uint256 amount, uint256 cancelTime);
    event SellerRestart(uint256 indexed orderNumber, address seller, uint256 amount, uint256 restartTime);
    event SellerOutRestart( uint256 indexed orderNumber, address seller, uint256 amount, uint256 outRestartTime);
    event SellerRedeem(uint256 indexed orderNumber, address seller, uint256 amount, uint256 redeemTime);
    event BuyerSubmit(uint256 indexed orderNumber, address seller, uint256 amount, address buyer, uint256 buyerSubmitTime);
    event BuyerCancelPayment(uint256 indexed orderNumber, address seller, uint256 amount,  address buyer, uint256 buyerCancelTime);
    event BuyerConfirmPayment(uint256 indexed orderNumber, address seller, uint256 amount, address buyer, uint256 buyerConfirmTime);
    event BuyerOutofTimeRestart(uint256 indexed orderNumber, address seller,uint256 amount, address buyer, uint256 restart);
    event SellerConfirmReceive(uint256 indexed orderNumber, address seller, uint256 amount, address buyer, uint256 sellerConfirmTime);
    event FallbackToBuyer(uint256 indexed orderNumber, address seller, uint256 amount, address buyer, uint256 fallbackTime); 
    event SellerOutofTime(uint256 indexed orderNumber, address seller, uint256 amount, address buyer, uint256 buyerWithdraw);

    //卖家发布卖单
    function setOrder(uint256 _orderNumber, uint256 _amount, uint256 _price, bool _isTrust)
        public 
    {       
        require(_amount > 0);
        id += 1;
        orders[id].orderNumber = _orderNumber;
        orders[id].seller = msg.sender;
        orders[id].amount = _amount;
        orders[id].price = _price;
        orders[id].isTrust = _isTrust;
        orders[id].submitTime = block.timestamp;
        orders[id].numberOfRounds = 0;

        WETH.transferFrom(msg.sender, feeTo, _amount.div(1000));
        WETH.transferFrom(msg.sender, address(this), _amount);

        emit SetOrder(_orderNumber, msg.sender, _amount, _isTrust, block.timestamp);
    }

    //卖家暂停卖单
    function sellerSuspend(uint256 _uid)
        public
        inState(_uid, State.SellerCreated)
        onlySeller(_uid)
        orderInTime(_uid)
    {
        orders[_uid].state = State.SellerSuspend;
        emit SellerSuspend(orders[_uid].orderNumber, msg.sender, orders[_uid].amount, block.timestamp);
    }

    //卖家取消卖单并赎回资金
    function cancelOrder(uint256 _uid)
        public
        inState(_uid, State.SellerCreated)
        onlySeller(_uid)
        orderInTime(_uid)
    {
        orders[_uid].state = State.SellerCancelled;
        WETH.transfer(msg.sender, orders[_uid].amount);
        emit CancelOrder(orders[_uid].orderNumber, msg.sender, orders[_uid].amount, block.timestamp);
    }

    //卖单暂停后，卖家重启卖单
    function sellerRestart(uint256 _uid)
        public
        inState(_uid, State.SellerSuspend)
        onlySeller(_uid)
    {
        orders[_uid].submitTime = block.timestamp;
        orders[_uid].state = State.SellerCreated;
        emit SellerRestart(orders[_uid].orderNumber, msg.sender, orders[_uid].amount, block.timestamp);
    }

    //卖单超时，卖家重启卖单
    function sellerOutRestart(uint256 _uid)
        public
        inState(_uid, State.SellerCreated)
        onlySeller(_uid)
        orderOutOfTime(_uid)
    {
        orders[_uid].submitTime = block.timestamp;
        emit SellerOutRestart(orders[_uid].orderNumber, msg.sender, orders[_uid].amount, block.timestamp);
    }

    //卖单超时，卖家赎回资金
    function sellerRedeem(uint256 _uid)
        public
        inState(_uid, State.SellerCreated)
        onlySeller(_uid)
        orderOutOfTime(_uid)
    {
        orders[_uid].state = State.SellerRedeem;
        WETH.transfer(msg.sender, orders[_uid].amount);
        emit SellerRedeem(orders[_uid].orderNumber, msg.sender, orders[_uid].amount, block.timestamp);
    }

    //买家提交买单
    function buyerSubmit(uint256 _uid) 
        public
        inState(_uid, State.SellerCreated)
        orderInTime(_uid)
    {   
        require(orders[_uid].seller != msg.sender);

        if(orders[_uid].isTrust == true){
            require(userTrust.inTrustLists(orders[_uid].seller, msg.sender));
        }

        orders[_uid].buyer = msg.sender;
        orders[_uid].submitTime = block.timestamp;
        orders[_uid].state = State.BuyerSubmit;
        emit BuyerSubmit(orders[_uid].orderNumber, orders[_uid].seller, orders[_uid].amount, msg.sender, block.timestamp);
    }

    //买家取消买单
    function buyerCancelPayment(uint256 _uid) 
        public
        inState(_uid, State.BuyerSubmit)
        onlyBuyer(_uid)
        ConfirmInTime(_uid)
    {   
        orders[_uid].submitTime = block.timestamp;
        orders[_uid].buyer = address(0);
        orders[_uid].state = State.SellerCreated;
        emit BuyerCancelPayment(orders[_uid].orderNumber, orders[_uid].seller, orders[_uid].amount, msg.sender, block.timestamp);
    }

    //买家确认付款
    function buyerConfirmPayment(uint256 _uid) 
        public
        inState(_uid, State.BuyerSubmit)
        onlyBuyer(_uid)
        ConfirmInTime(_uid)
    {   
        orders[_uid].submitTime = block.timestamp;
        orders[_uid].numberOfRounds += 1;
        orders[_uid].state = State.BuyerConfirmPayment;
        emit BuyerConfirmPayment(orders[_uid].orderNumber, orders[_uid].seller, orders[_uid].amount, msg.sender, block.timestamp);
    }

    //买家超时未付款，卖家重置卖单
    function buyerOutofTimeRestart(uint256 _uid) 
        public
        inState(_uid, State.BuyerSubmit)
        onlySeller(_uid)
        ConfirmOutOfTime(_uid)
    {   
        emit BuyerOutofTimeRestart(orders[_uid].orderNumber, msg.sender, orders[_uid].amount, orders[_uid].buyer, block.timestamp);

        orders[_uid].submitTime = block.timestamp;
        orders[_uid].buyer = address(0);
        orders[_uid].numberOfRounds = 0;
        orders[_uid].state = State.SellerCreated;
    }
    
    //卖家确认收款并放行资金。
    //如果第一轮就成功，则奖励10个锤子，卖家6个，买家4个
    function sellerConfirmReceive(uint256 _uid)
        public
        inState(_uid, State.BuyerConfirmPayment)
        onlySeller(_uid)
        ConfirmInTime(_uid)
    {
        WETH.transfer(orders[_uid].buyer, orders[_uid].amount);
        orders[_uid].state = State.SellerConfirmReceive;

        if(orders[_uid].numberOfRounds == 1){
            HAMMER.mint(orders[_uid].seller, 6 * 1e18);
            HAMMER.mint(orders[_uid].buyer, 4 * 1e18);
        }
        
        emit SellerConfirmReceive(orders[_uid].orderNumber, msg.sender, orders[_uid].amount, orders[_uid].buyer, block.timestamp);
    }

    //卖家未收到付款，退回卖单给买家
    function fallbackToBuyer(uint256 _uid) 
        public
        inState(_uid, State.BuyerConfirmPayment)
        onlySeller(_uid)
        ConfirmInTime(_uid)
    {   
        orders[_uid].submitTime = block.timestamp;
        orders[_uid].state = State.BuyerSubmit;
        emit FallbackToBuyer(orders[_uid].orderNumber, msg.sender, orders[_uid].amount, orders[_uid].buyer, block.timestamp);
    }

    //卖家超时未确认，买家取出资金
    function sellerOutofTime(uint256 _uid)
        public
        inState(_uid, State.BuyerConfirmPayment)
        onlyBuyer(_uid)
        ConfirmOutOfTime(_uid)
    {
        WETH.transfer(msg.sender, orders[_uid].amount);
        orders[_uid].state = State.SellerOutofTime;
        emit SellerOutofTime(orders[_uid].orderNumber, orders[_uid].seller, orders[_uid].amount, msg.sender, block.timestamp);
    }
}
