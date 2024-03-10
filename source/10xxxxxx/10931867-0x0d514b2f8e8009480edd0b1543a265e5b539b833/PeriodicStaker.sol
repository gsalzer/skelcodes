/* 
 *  PeriodicStaker
 *  VERSION: 3
 *
 */

contract ERC20{
    function allowance(address owner, address spender) external view returns (uint256){}
    function transfer(address recipient, uint256 amount) external returns (bool){}
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool){}
    function balanceOf(address account) external view returns (uint256){}
}

contract PeriodicStaker {
    

    event Staked(address staker);


    ERC20 public token;
    uint public total_stake=0;
    uint public total_stakers=0;
    mapping(address => uint)public stake;
    
    uint public status=0; //0=open , 1=can't unstake , 2 can't stake
    
    uint safeWindow=20;//40320;
    
    uint public startLock;
    uint public lockTime;
    uint minLock=10;//17280;
    uint maxLock=60;//17280s0;
    
    uint public freezeTime;
    uint minFreeze=10;//17280;
    uint maxFreeze=60;//40320;

    address public master;

    

    constructor(address tokenToStake,address mastr) public {
        token=ERC20(tokenToStake);
        master=mastr;
    }
    

    function stakeNow(uint256 amount) public {
        require(amount > 0);
        require(status!=2);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount);
        require(token.transferFrom(msg.sender, address(this), amount));
        if(stake[msg.sender]==0)total_stakers++;
        stake[msg.sender]+=amount;
        total_stake+=amount;
        
        emit Staked(msg.sender);
    }
    
    function unstake() public {
        require(stake[msg.sender] > 0);
        if(status==1)require((startLock+lockTime)<block.number);
        require(token.transfer(msg.sender, stake[msg.sender]));
        total_stake-=stake[msg.sender];
        stake[msg.sender]=0;
        total_stakers--;

    }
    
    function openDropping(uint lock) public{
        require(msg.sender==master);
        require(block.number>startLock+safeWindow);
        require(minLock<=lock);
        require(lock<=maxLock);
        require(status==0);
        status=1;
        lockTime=lock;
        startLock=block.number;
    }
    
    function freeze(uint freez) public{
        require(msg.sender==master);
        require(block.number>startLock+safeWindow);
        require(minFreeze<=freez);
        require(freez<=maxFreeze);
        require(status==0);
        status=2;
        freezeTime=freez;
        startLock=block.number;
    }
    
    function open() public{
        require(status>0);
        if(status==1)require(block.number>startLock+lockTime);
        if(status==2)require(block.number>startLock+freezeTime);
        startLock=block.number;
        status=0;
        
    }
    
    function setMaster(address new_master)public returns(bool){
        require(msg.sender!=master);
        master=new_master;
        return true;
    }
    
    function status()public view returns(uint){return status;}

}

contract TokenDropper{
    
    PeriodicStaker public staker;
    ERC20 public token;
    mapping(address => bool)public rewarded;
    uint public multiplier;
    address master;
    address public receiver;
    
    constructor(address staker_contract,uint multip,address token_address,address destination) public{
        staker=PeriodicStaker(staker_contract);
        multiplier=multip;
        token=ERC20(token_address);
        master=msg.sender;
        receiver=destination;
    }
    
    function Pull_Reward() public{
        require(!rewarded[msg.sender]);
        require(staker.status()>0);
        require(token.transfer(msg.sender, staker.stake(msg.sender)*multiplier));
        rewarded[msg.sender]=true;
    }
    
    function burn()public returns(bool){
        require(staker.status()==0);
        token.transfer(receiver, token.balanceOf(address(this)));
    }
    
}
