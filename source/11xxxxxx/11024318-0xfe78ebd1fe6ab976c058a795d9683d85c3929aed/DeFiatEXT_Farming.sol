pragma solidity ^0.6.0;

import "./SafeMath.sol";
import {IERC20, IDungeon} from "./_Interfaces.sol";

// File: @defiat-crypto/defiat/blob/master/contracts/XXXXXX.sol
/**
 * @dev Delegated Farming Contract.
 * Implements a conditoin on the DFT-DFT farming pool for users to generate more rewards
 */
contract DeFiat_EXTFarming_V2 {
    using SafeMath for uint256;

    //Structs
    struct PoolMetrics {
        address stakedToken;
        uint256 staked;         // sum of tokens staked in the contract
        uint256 stakingFee;     // entry fee
        
        uint256 stakingPoints;

        address rewardToken;
        uint256 rewards;        // current rewards in the pool
        uint256 totalRewards;

        uint256 startTime;      // when the pool opens
        uint256 closingTime;    // when the pool closes. 
        uint256 duration;       // duration of the staking
        uint256 lastEvent;      // last time metrics were updated.
        
        uint256  ratePerToken;  // CALCULATED pool reward Rate per Token (calculated based on total stake and time)
        
        address DftDungeon;     // used to calculate the DeFiatScore
        bool boostedRewards;
    }
    PoolMetrics public poolMetrics;

    struct UserMetrics {
        uint256 stake;          // native token stake (balanceOf)
        uint256 stakingPoints;  // staking points at lastEvent
        uint256 poolPoints;     // pool point at lastEvent
        uint256 lastEvent;

        uint256 rewardAccrued;  // accrued rewards over time based on staking points
        uint256 rewardsPaid;    // for information only

        uint256 lastTxBlock;    // latest transaction from the user (antiSpam)
    }
    mapping(address => UserMetrics) public userMetrics;
    
        address public poolOperator; address public owner;
        

//== constructor 
    constructor(address _stakedToken, address _rewardToken, uint256 _feeBase1000, uint256 _durationHours) public {
        owner = msg.sender;
        poolOperator = msg.sender;
        
        poolMetrics.stakedToken = address(_stakedToken);
        poolMetrics.rewardToken = address(_rewardToken);
        poolMetrics.stakingFee = _feeBase1000; //10 = 1%
        
        poolMetrics.duration = _durationHours.mul(3600); //
        poolMetrics.startTime = block.timestamp;
        poolMetrics.closingTime = block.timestamp + poolMetrics.duration;
        
        poolMetrics.stakingPoints = 1; //avoirds div by 0 at start
        poolMetrics.boostedRewards = true;
    }

//==Events
    event PoolInitalized(uint256 amountAdded, string  _desc);
    event RewardTaken(address indexed user, uint256 reward, string  _desc);

    event userStaking(address indexed user, uint256 amount, string  _desc);
    event userWithdrawal(address indexed user, uint256 amount, string  _desc);

    modifier poolLive() {
        require(block.timestamp >= poolMetrics.startTime,"Pool not started Yet"); //good for delayed starts.
        require(block.timestamp <= poolMetrics.closingTime,"Pool closed"); //good for delayed starts.
        _;
    }
    modifier poolStarted() {
        require(block.timestamp >= poolMetrics.startTime,"Pool not started Yet"); //good for delayed starts.
        _;
    }
    modifier poolEnded() {
        require(block.timestamp > poolMetrics.closingTime,"Pool not ended Yet"); //good for delayed starts.
        _;
    }
    
    modifier antiSpam(uint256 _blocks) {
        require(block.number > userMetrics[msg.sender].lastTxBlock.add(_blocks), "Wait X BLOCKS between Transactions");
        userMetrics[msg.sender].lastTxBlock = block.number; //update
        _;
    } 
    modifier onlyPoolOperator() {
        require(msg.sender== poolOperator || msg.sender == owner, "msg.sender is not allowed to operate Pool");
        _;
    }
    modifier onlyOwner() {
        require(msg.sender== owner, "Only Owner");
        _;
    }
    modifier antiWhale(address _address) {
        require(myStakeShare(_address) < 20000, "User stake% share too high. Leave some for the smaller guys ;-)"); //max 20%
        _;
    } 
    // avoids stakes being deposited once a user reached 20%. 
    // Simplistic implementation as if we calculate "futureStake" value very 1st stakers will not be able to deposit.
    
    
//==Basics 
    function currentTime() public view returns (uint256) {
        return SafeMath.min(block.timestamp, poolMetrics.closingTime); //allows expiration
    } // SafeMath.min(now, endTime)
    
//==DeFiat Boost
    function setDungeon(address _dungeon) public onlyOwner {
        poolMetrics.DftDungeon = _dungeon;
    }
    
    /**
    * @dev Function gets the amount of DFT in the DFT dungeon farm 
    * to calculate a score that boosts the StakingRewards calculation
    * DFT requirements to get a boost are hard coded into the contract
    * 0DFT to 100 DFT staked respectfully generate a 0% to 100% bonus on Staking.
    * returned is a number between 50 and 100
    */
    function viewDftBoost(address _address) public view returns(uint256) {
        uint256 _userStake = IDungeon(poolMetrics.DftDungeon).myStake(_address).div(1e18);
        return SafeMath.min(200, _userStake.add(100));
    }
    
//==Points locking    
    function viewPoolPoints() public view returns(uint256) {
        uint256 _previousPoints = poolMetrics.stakingPoints;    // previous points shapshot 
        uint256 _previousStake = poolMetrics.staked;             // previous stake snapshot
        
        uint256 _timeHeld = currentTime().sub(
                    SafeMath.max(poolMetrics.lastEvent, poolMetrics.startTime)
                                                );                 // time held with _previous Event
                                                
        return  _previousPoints.add(_previousStake.mul(_timeHeld));    //generated points since event
    }

    function lockPoolPoints() internal returns (uint256) { //ON STAKE/UNSTAKE EVENT
        poolMetrics.stakingPoints = viewPoolPoints();
        poolMetrics.lastEvent = currentTime();   // update lastStakingEvent
        return poolMetrics.stakingPoints;
    } 
    
    function viewPointsOf(address _address) public view returns(uint256) {
        uint256 _previousPoints = userMetrics[_address].stakingPoints;    
        uint256 _previousStake = userMetrics[_address].stake; // boosted stake before event
    
        uint256 _timeHeld = currentTime().sub(
                    SafeMath.max(userMetrics[_address].lastEvent, poolMetrics.startTime)
                                                );                          // time held since lastEvent (take RWD, STK, unSTK)
        
        uint256 _result = _previousPoints.add(_previousStake.mul(_timeHeld));   
        
        if(_result > poolMetrics.stakingPoints){_result = poolMetrics.stakingPoints;}
        
        
        return _result;
    }

    function lockPointsOf(address _address) internal returns (uint256) {
        userMetrics[_address].poolPoints = viewPoolPoints();  // snapshot of pool points at lockEvent
        userMetrics[_address].stakingPoints = viewPointsOf(_address); 
        userMetrics[_address].lastEvent = currentTime(); 

        return userMetrics[_address].stakingPoints;
    }

    function pointsSnapshot(address _address) public returns (bool) {
        lockPointsOf(_address);
        lockPoolPoints();
        return true;
    }
     
    //==Rewards
    function viewTrancheReward(uint256 _period) internal view returns(uint256) {
        //uint256 _poolRewards = poolMetrics.rewards; //tokens in the pool. Note: This can be setup to a fixed amount (totalRewards)
        uint256 _poolRewards = poolMetrics.totalRewards; 
        
        if(poolMetrics.boostedRewards == false){ _poolRewards = SafeMath.min(poolMetrics.staked, _poolRewards);} 
        // baseline is the min( staked, rewards); avoids ultra_farming > staking pool - EXPERIMENTAL
        
        uint256 _timeRate = _period.mul(1e18).div(poolMetrics.duration);
        return _poolRewards.mul(_timeRate).div(1e18); //tranche of rewards on period
    }
    
    function userRateOnPeriod(address _address) public view returns (uint256){
        //calculates the delta of pool points and user points since last Event
        uint256 _deltaUser = viewPointsOf(_address).sub(userMetrics[_address].stakingPoints); // points generated since lastEvent
        uint256 _deltaPool = viewPoolPoints().sub(userMetrics[_address].poolPoints);          // pool points generated since lastEvent
        uint256 _rate = 0;
        if(_deltaUser == 0 || _deltaPool == 0 ){_rate = 0;} //rounding
        else {_rate = _deltaUser.mul(1e18).div(_deltaPool);}
        
        return viewDftBoost(_address).mul(_rate).div(200); //applies bossted rate on period based on the DFT in the dungeon.
    }
    
    function viewAdditionalRewardOf(address _address) public view returns(uint256) { // rewards generated since last Event
        require(poolMetrics.rewards > 0, "No Rewards in the Pool");
        
        // user weighted average share of Pool since lastEvent
        uint256 _userRateOnPeriod = userRateOnPeriod(_address); //can drop if pool size increases within period -> slows rewards generation
        
        // Pool Yield Rate 
        uint256 _period = currentTime().sub(
                            SafeMath.max(userMetrics[_address].lastEvent, poolMetrics.startTime)  
                            );        // time elapsed since last reward or pool started (if never taken rewards)

        // Calculate reward
        uint256 _reward = viewTrancheReward(_period).mul(_userRateOnPeriod).div(1e18);  //user rate on pool rewards' tranche

        return _reward;
    }
    
    function lockRewardOf(address _address) public returns(uint256) {
        uint256 _additional = viewAdditionalRewardOf(_address); //stakeShare(sinceLastEvent) * poolRewards(sinceLastEvent)
        userMetrics[_address].rewardAccrued = userMetrics[_address].rewardAccrued.add(_additional); //snapshot rewards.
        
        pointsSnapshot(_address); //updates lastEvent and points
        return userMetrics[_address].rewardAccrued;
    }  
    
    function takeRewards() public poolStarted antiSpam(1) { //1 blocks between rewards
        require(poolMetrics.rewards > 0, "No Rewards in the Pool");
        
        uint256 _reward = lockRewardOf(msg.sender); //returns already accrued + additional (also resets time counters)

        userMetrics[msg.sender].rewardsPaid = _reward;   // update user paid rewards
        
        userMetrics[msg.sender].rewardAccrued = 0; //flush previously accrued rewards.
        
        poolMetrics.rewards = poolMetrics.rewards.sub(_reward);           // update pool rewards
            
        IERC20(poolMetrics.rewardToken).transfer(msg.sender, _reward);  // transfer
            
        pointsSnapshot(msg.sender); //updates lastEvent
        //lockRewardOf(msg.sender);
            
        emit RewardTaken(msg.sender, _reward, "Rewards Sent");          
    }
    
//==staking & unstaking

    function stake(uint256 _amount) public poolLive antiSpam(1) antiWhale(msg.sender){
        require(_amount > 0, "Cannot stake 0");
        
        //initialize
        userMetrics[msg.sender].rewardAccrued = lockRewardOf(msg.sender); //Locks previous eligible rewards based on lastRewardEvent and lastStakingEvent
        pointsSnapshot(msg.sender);

        //receive staked
        uint256 _balanceNow = IERC20(address(poolMetrics.stakedToken)).balanceOf(address(this));
        IERC20(poolMetrics.stakedToken).transferFrom(msg.sender, address(this), _amount); //will require allowance
        uint256 amount = IERC20(address(poolMetrics.stakedToken)).balanceOf(address(this)).sub(_balanceNow); //actually received
        
        //update pool and user based on stake and fee
        uint256 _fee = amount.mul(poolMetrics.stakingFee).div(1000);
        amount = amount.sub(_fee);
        
        if(poolMetrics.stakedToken == poolMetrics.rewardToken){poolMetrics.rewards = poolMetrics.rewards.add(_fee);}
        poolMetrics.staked = poolMetrics.staked.add(amount);
        userMetrics[msg.sender].stake = userMetrics[msg.sender].stake.add(amount);

        //finalize
        pointsSnapshot(msg.sender); //updates lastEvent
        emit userStaking(msg.sender, amount, "Staking... ... ");
        
    } 
    
    function unStake(uint256 _amount) public poolStarted antiSpam(1) { 
        require(_amount > 0, "Cannot withdraw 0");
        require(_amount <= userMetrics[msg.sender].stake, "Cannot withdraw more than stake");

        //initialize
        userMetrics[msg.sender].rewardAccrued = lockRewardOf(msg.sender); //snapshot of  previous eligible rewards based on lastStakingEvent
        pointsSnapshot(msg.sender);

        // update metrics
        userMetrics[msg.sender].stake = userMetrics[msg.sender].stake.sub(_amount);
        poolMetrics.staked = poolMetrics.staked.sub(_amount);

        // transfer _amount. Put at the end of the function to avoid reentrancy.
        IERC20(poolMetrics.stakedToken).transfer(msg.sender, _amount);
        
        //finalize
        emit userWithdrawal(msg.sender, _amount, "Widhtdrawal");
    }

    function myStake(address _address) public view returns(uint256) {
        return userMetrics[_address].stake;
    }

    function myStakeShare(address _address) public view returns(uint256) {
        if(poolMetrics.staked == 0){return 0;}
        else {
        return (userMetrics[_address].stake).mul(100000).div(poolMetrics.staked);}
    } //base 100,000

    function myPointsShare(address _address) public view returns(uint256) {  //weighted average of your stake over time vs the pool
        return viewPointsOf(_address).mul(100000).div(viewPoolPoints());
    } //base 100,000. Drops when taking rewards.=> Refills after (favors strong hands)

    function myRewards(address _address) public view returns(uint256) {
        //delayed start obfuscation (avoids disturbances in the force...)
        if(block.timestamp <= poolMetrics.startTime || poolMetrics.rewards == 0){return 0;}
        else { return userMetrics[_address].rewardAccrued.add(viewAdditionalRewardOf(_address));} //previousLock + time based extra
    }
 

//== OPERATOR FUNCTIONS ==
    
    function setBoostedRewards(bool _bool) public onlyPoolOperator {
        poolMetrics.boostedRewards = _bool;
    }

    function loadRewards(uint256 _amount, uint256 _preStake) public onlyPoolOperator { //load tokens in the rewards pool.
        
        uint256 _balanceNow = IERC20(address(poolMetrics.rewardToken)).balanceOf(address(this));
        IERC20(address(poolMetrics.rewardToken)).transferFrom( msg.sender,  address(this),  _amount);
        uint256 amount = IERC20(address(poolMetrics.rewardToken)).balanceOf(address(this)).sub(_balanceNow); //actually received
        

        if(poolMetrics.rewards == 0){                                   // initialization
        poolMetrics.staked = SafeMath.add(poolMetrics.staked,_preStake);}  // creates baseline for pool. Avoids massive movements on rewards
        
        poolMetrics.rewards = SafeMath.add(poolMetrics.rewards,amount);
        poolMetrics.totalRewards = poolMetrics.totalRewards.add(_amount);
    }    
    
    function flushPool(address _recipient, address _ERC20address) external onlyPoolOperator poolEnded {
        uint256 _amount = IERC20(_ERC20address).balanceOf(address(this));
        IERC20(_ERC20address).transfer(_recipient, _amount); //use of the _ERC20 traditional transfer
        //return true;
    } //get tokens sent by error to contract

    function setPoolOperator(address _address) public onlyPoolOperator {
        poolOperator = _address;
    }
    
    function setFee(uint256 _fee) public onlyOwner {
        poolMetrics.stakingFee = _fee;
    }
    
    function killPool() public onlyOwner poolEnded returns(bool) {
        selfdestruct(msg.sender);
    } //frees space on the ETH chain

}

