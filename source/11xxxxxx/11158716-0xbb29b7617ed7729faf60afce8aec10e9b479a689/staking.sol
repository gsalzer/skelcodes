pragma solidity <=7.0.2;

import './myfi.sol';

contract Math {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract Staking is Math {
    MoonYFI public myfi;
    uint256[4] public rFactors = [0,210000000000,130000000000,90000000000];
    uint256 public currentLevel = 0;
    uint256 public nextLevel = 0;
    address public owner;

    constructor(address contract_address) public{
        myfi = MoonYFI(contract_address);
        currentLevel = currentLevel + 1;
        nextLevel = nextLevel + 180 days;
        owner = msg.sender;
    }
    
    struct User {
        uint256 currentStake;
        uint256 rewardsClaimed;
        uint256 totalClaimed;
        uint256 block;
        bool active;
    }
    
    struct History{
        uint256 staked;
        uint256 claimed;
        uint256 startingBlock;
        uint256 endingBlock;
        uint256 time;
    }
    
    mapping(address => User) public users;
    
    mapping(address => mapping(uint256 => History)) public history;
    
    function stake(uint256 amount_stake) public returns(bool){
        require(myfi.allowance(msg.sender,address(this))>=amount_stake,'Allowance Exceeded');
        User storage u = users[msg.sender];
        require(u.currentStake == 0,'Already Staked');
        u.currentStake = amount_stake;
        u.block = block.number;
        u.active = true;
        myfi.transferFrom(msg.sender,address(this),amount_stake);
        return true;
    }
    
    function claim() public returns(bool){
        User storage u = users[msg.sender];
        require(u.active == true,'Invalid User');
        uint256 d = Math.sub(block.number,u.block);
        uint256 f = Math.mul(d,rFactors[currentLevel]);
        uint256 r1 = Math.mul(u.currentStake,f);
        uint256 r = Math.div(r1,10**18);
        uint256 s = Math.add(r,u.currentStake);
        myfi.transfer(msg.sender,s);
        History storage h = history[msg.sender][u.totalClaimed];
        h.staked = u.currentStake;
        h.claimed = s;
        h.startingBlock = u.block;
        h.endingBlock = block.number;
        h.time = block.timestamp;
        if(block.timestamp > nextLevel && currentLevel < 4){currentLevel=currentLevel+1;nextLevel = nextLevel + 180 days;}
        u.rewardsClaimed = u.rewardsClaimed + r;
        u.block = 0;
        u.currentStake = 0;
        u.totalClaimed = u.totalClaimed + 1;
        return true;
    }
    
    function fetchUnclaimed() public view returns(uint256){
        User storage u = users[msg.sender];
        require(u.active == true,'Invalid User');
        require(u.currentStake >= 0,'No Stake');
        uint256 d = Math.sub(block.number,u.block);
        uint256 f = Math.mul(d,rFactors[currentLevel]);
        uint256 r1 = Math.mul(u.currentStake,f);
        uint256 r = Math.div(r1,10**18);
        return(r);
    }
    
    function fetchRewardHistory(uint256 id) public view returns(uint256 staked, uint256 claimed, uint256 startingBlock, uint256 endingBlock, uint256 time){
        History storage h = history[msg.sender][id];
        return (h.staked,h.claimed,h.startingBlock,h.endingBlock,h.time);
    }
    
    function updateReward() public returns(bool){
        require(msg.sender == owner, 'Caller not owner');
        currentLevel=currentLevel+1;
        nextLevel = nextLevel + 180 days;
        return true;
    }
    
    function fetchBlockNumber() public view returns(uint256){
        return block.number;
    }
    
    function drain() public returns(bool){
        require(msg.sender == owner);
        uint256 b = myfi.balanceOf(address(this));
        myfi.transfer(owner,b);
        return true;
    }
}
