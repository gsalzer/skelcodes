pragma solidity ^0.5.5;
library SafeMath{

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256){
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256){
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256){
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
contract FWStorage {
    modifier isOwner() {
        require(msg.sender == _owner);
        _;
    }
    struct User{
        address userAddress;
        uint investAmount;   //投资的数量
        uint allInvestAmount;   //
        address inviter;    //邀请我的人
        address[] children; //我直接邀请的人
        uint invitersCount;   //本月邀请的人数ETH,参与竞赛
        uint achieveTime;   //达成时间
        uint annualRing;  //经历过的轮数
        uint64 referCode;   //我的邀请码
         uint birth;               //初次投资时间
         uint rebirth;             //本轮生效时间
         uint gottenStaticProfit;
         uint gottenDynamicProfit;
        bool inserted;
    }
    address _owner;
    address[] public investors;
    mapping (address => User) public addressToUser;
    mapping (uint64 => address) public codeToAddress;
    //最小投资eth数量
    uint256 minInvest;
    //最大投资eth数量
    uint256 maxInvest;
    //第一位邀请人推荐码
    uint64 currentReferCode;

    //全球节点
    uint256 public globalNodeNumber = 0;
    //合约总量
    uint256 public totalInvestAmount;  //总流水
    
    uint256 public insertedNodeNumber = 0;
    uint256 public insertedAmount;

    //用于接收直接打入合约的以太币
    uint256 public ethMissPool; //balance direct send to this contract ,sorry ,it will not in ethFundPool
    uint256 public racePool;   //基金数量 ,用于发放竞赛的资金   充值的1%
    // address racePool;  //基金,用于发放竞赛的资金   充值的1%
    address fusePool;     //保险池,入金最后一名投资额的10倍奖励,最后99名平分  动态的20%
    address guaranteePool;    //保障池       提现扣手续费
    address foundingPool;     //创始团队     充值的1%
    address appFund;          //应用专款     充值的2%
    uint256 oneLoop = 24 hours;
    uint256 roundOfLoop = 9;
    uint256 contractBirthDay;
    address[] public topUsers;
    constructor() public{
        _owner = msg.sender;
        minInvest = 1 ether;
        maxInvest = 29 ether;
        currentReferCode = 218870;
        // empty.push(this);
        User memory creation = User(msg.sender, minInvest,minInvest, address(0x0), new address[](0),0, 0,0,currentReferCode,now, now,0,0, false);
        topUsers = new address[](9);
    addressToUser[msg.sender] = creation;
    codeToAddress[currentReferCode] = msg.sender;
    currentReferCode = currentReferCode + 9;
    contractBirthDay = now;
    fusePool = msg.sender;
    guaranteePool = msg.sender;
    foundingPool = msg.sender;
    appFund = msg.sender;
    }
}
