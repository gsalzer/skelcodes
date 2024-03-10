// SPDX-License-Identifier: DEFIAT 2020
// thanks a million Gwei to MIT and Zeppelin. You guys rock!!!

// MAINNET VERSION. 

/*
*Website: www.defiat.net
*Telegram: https://t.me/defiat_crypto
*Twitter: https://twitter.com/DeFiatCrypto
*/

pragma solidity ^0.6.6;

import "./Libraries.sol";
import "./Interfaces.sol";


contract Rug_Sanctuary {
    using SafeMath for uint256;


    address public second; //token address
    
    address public Treasury;
    uint256 public treasuryFee;
    uint256 public pendingTreasuryRewards;
    

//USERS METRICS
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 rewardPaid; // Already Paid. See explanation below.
        //  pending reward = (user.amount * pool.secondPerShare) - user.rewardPaid
    }
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    
//POOL METRICS
    struct PoolInfo {
        address stakedToken;            // Address of staked token contract.
        uint256 allocPoint;             // How many allocation points assigned to this pool. 2nd to distribute per block. (ETH = 2.3M blocks per year)
        uint256 accPerShare;            // Accumulated 2nd per share, times 1e18. See below.
        bool withdrawable;              // Is this pool withdrawable or not
        
        mapping(address => mapping(address => uint256)) allowance;
    }
    PoolInfo[] public poolInfo;

    uint256 public lockRatio100;        // How much UNIv2 is given back (%)
    
    uint256 public totalAllocPoint;     //Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public pendingRewards;      // pending rewards awaiting anyone to massUpdate
    uint256 public contractStartBlock;
    uint256 public epochCalculationStartBlock;
    uint256 public cumulativeRewardsSinceStart;
    uint256 public rewardsInThisEpoch;
    uint public epoch;

//EVENTS
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 _pid, uint256 value);

    
//INITIALIZE 
    constructor(address _second) public {

        second  = _second;
        
        Treasury = address(0x0419eB10E9c1efFb47Cb6b5B1B2B2B3556395ae1); //DeFiat Treasury
        treasuryFee = 100; //10% -> used for DFT buybacks
        
        lockRatio100 = 90; //10% of UniV2 given back
        
        contractStartBlock = block.number;
    }
    
//==================================================================================================================================
//POOL
    
 //view stuff
 
    function poolLength() external view returns (uint256) {
        return poolInfo.length; //number of pools (per pid)
    }
    
    // Returns fees generated since start of this contract
    function averageFeesPerBlockSinceStart() external view returns (uint averagePerBlock) {
        averagePerBlock = cumulativeRewardsSinceStart.add(rewardsInThisEpoch).div(block.number.sub(contractStartBlock));
    }

    // Returns averge fees in this epoch
    function averageFeesPerBlockEpoch() external view returns (uint256 averagePerBlock) {
        averagePerBlock = rewardsInThisEpoch.div(block.number.sub(epochCalculationStartBlock));
    }

    // For easy graphing historical epoch rewards
    mapping(uint => uint256) public epochRewards;

 //set stuff (govenrors)

    // Add a new token pool. Can only be called by governors.
    function addPool( uint256 _allocPoint, address _stakedToken, bool _withdrawable) public onlyAllowed {
        require(_allocPoint > 0, "Zero alloc points not allowed");
        nonWithdrawableByAdmin[_stakedToken] = true; // stakedToken is now non-widthrawable by the admins.
        
        /* @dev Addressing potential issues with zombie pools.
        *  https://medium.com/@DraculaProtocol/sushiswap-smart-contract-bug-and-quality-of-audits-in-community-f50ee0545bc6
        *  Thank you @DraculaProtocol for this interesting post.
        */
        massUpdatePools();

        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].stakedToken != _stakedToken,"Error pool already added");
        }

        totalAllocPoint = totalAllocPoint.add(_allocPoint); //pre-allocation

        poolInfo.push(
            PoolInfo({
                stakedToken: _stakedToken,
                allocPoint: _allocPoint,
                accPerShare: 0,
                withdrawable : _withdrawable
            })
        );
    }

    // Updates the given pool's  allocation points. Can only be called with right governance levels.
    function setPool(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyAllowed {
        if (_withUpdate) {massUpdatePools();}
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Update the given pool's ability to withdraw tokens
    function setPoolWithdrawable(uint256 _pid, bool _withdrawable) public onlyAllowed {
        poolInfo[_pid].withdrawable = _withdrawable;
    }
    
    
    
 //set stuff (anybody)
  
    //Starts a new calculation epoch; Because average since start will not be accurate
    function startNewEpoch() public {
        require(epochCalculationStartBlock + 50000 < block.number, "New epoch not ready yet"); // 50k blocks = About a week
        epochRewards[epoch] = rewardsInThisEpoch;
        cumulativeRewardsSinceStart = cumulativeRewardsSinceStart.add(rewardsInThisEpoch);
        rewardsInThisEpoch = 0;
        epochCalculationStartBlock = block.number;
        ++epoch;
    }
    
    // Updates the reward variables of the given pool
    function updatePool(uint256 _pid) internal returns (uint256 RewardWhole) {
        PoolInfo storage pool = poolInfo[_pid];

        uint256 tokenSupply = IERC20(pool.stakedToken).balanceOf(address(this));
        if (tokenSupply == 0) { // avoids division by 0 errors
            return 0;
        }
        RewardWhole = pendingRewards     // Multiplies pending rewards by allocation point of this pool and then total allocation
            .mul(pool.allocPoint)       // getting the percent of total pending rewards this pool should get
            .div(totalAllocPoint);      // we can do this because pools are only mass updated
        
        uint256 RewardFee = RewardWhole.mul(treasuryFee).div(1000);
        uint256 RewardToDistribute = RewardWhole.sub(RewardFee);

        pendingTreasuryRewards = pendingTreasuryRewards.add(RewardFee);

        pool.accPerShare = pool.accPerShare.add(RewardToDistribute.mul(1e18).div(tokenSupply));
    }
    function massUpdatePools() public {
        uint256 length = poolInfo.length; 
        uint allRewards;
        
        for (uint256 pid = 0; pid < length; ++pid) {
            allRewards = allRewards.add(updatePool(pid)); //calls updatePool(pid)
        }
        pendingRewards = pendingRewards.sub(allRewards);
    }
    
    //payout of Rewards, uses SafeUnicoreTransfer
    function updateAndPayOutPending(uint256 _pid, address user) internal {
        
        massUpdatePools();

        uint256 pending = pending(_pid, user);
        
        safe2NDTransfer(user, pending);
    }
    
    // Safe UniCore transfer function, Manages rounding errors.
    function safe2NDTransfer(address _to, uint256 _amount) internal {
        if(_amount == 0) return;

        uint256 secondBal = IERC20(second).balanceOf(address(this));
        if (_amount >= secondBal) { IERC20(second).transfer(_to, secondBal);} 
        else { IERC20(second).transfer(_to, _amount);}

        transferTreasuryFees(); //remainder
        secondBalance = IERC20(second).balanceOf(address(this));
    }

//external call from token when rewards are loaded

    /* @dev called by the token after each fee transfer to the vault.
    *       updates the pendingRewards and the rewardsInThisEpoch variables
    */      
    modifier onlyToken() {
        require(msg.sender == second);
        _;
    }
 
    uint256 private secondBalance;
    function updateRewards() external onlyToken {
        uint256 newRewards = IERC20(second).balanceOf(address(this)).sub(secondBalance); //delta vs previous balanceOf

        if(newRewards > 0) {
            secondBalance =  IERC20(second).balanceOf(address(this)); //balance snapshot
            pendingRewards = pendingRewards.add(newRewards);
            rewardsInThisEpoch = rewardsInThisEpoch.add(newRewards);
        }
    }

//==================================================================================================================================
//USERS
    
    /* protects from a potential reentrancy in Deposits and Withdraws 
     * users can only make 1 deposit or 1 wd per block
     */
     
    mapping(address => uint256) private lastTXBlock;
    modifier NoReentrant(address _address) {
        require(block.number > lastTXBlock[_address], "Wait 1 block between each deposit/withdrawal");
        _;
    }
    
    // Deposit tokens to Vault to get allocation rewards
    function deposit(uint256 _pid, uint256 _amount) external NoReentrant(msg.sender) {
        lastTXBlock[msg.sender] = block.number+1;
        
        require(_amount > 0, "cannot deposit zero tokens");
        
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updateAndPayOutPending(_pid, msg.sender); //Transfer pending tokens, updates the pools 

        //Transfer the amounts from user
        IERC20(pool.stakedToken).transferFrom(msg.sender, address(this), _amount);
        user.amount = user.amount.add(_amount);

        //Finalize
        user.rewardPaid = user.amount.mul(pool.accPerShare).div(1e18);
        
        emit Deposit(msg.sender, _pid, _amount);
    }

    /*  Withdraw tokens from Vault.
    *   Withdraws will be locked for 10 days when the protocol starts, then will open
    *   There is a penalty on WD: 25% of Univ2 stays locked
    */
    function withdraw(uint256 _pid, uint256 _amount) external NoReentrant(msg.sender) {
        lastTXBlock[msg.sender] = block.number+1; 
        _withdraw(_pid, _amount, msg.sender, msg.sender); //25% permanent lock
        transferTreasuryFees();
    }
    function _withdraw(uint256 _pid, uint256 _amount, address from, address to) internal {

        PoolInfo storage pool = poolInfo[_pid];
        require(pool.withdrawable, "Withdrawing from this pool is disabled");
        
        UserInfo storage user = userInfo[_pid][from];
        require(user.amount >= _amount, "withdraw: user amount insufficient");

        updateAndPayOutPending(_pid, from);

        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            _amount = _amount.mul(lockRatio100).div(100); // incur lock penalty 
            IERC20(pool.stakedToken).transfer(address(to), _amount);
        }
        user.rewardPaid = user.amount.mul(pool.accPerShare).div(1e18);
        emit Withdraw(to, _pid, _amount);
    }

    // Getter function to see pending rewards per user.
    function pending(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accPerShare = pool.accPerShare;
        
        return user.amount.mul(accPerShare).div(1e18).sub(user.rewardPaid);
    }

//==================================================================================================================================
//TREASURY 

    function transferTreasuryFees() public {
        if(pendingTreasuryRewards == 0) return;

        uint256 secondBal = IERC20(second).balanceOf(address(this));
        
        //manages overflows or bad math
        if (pendingTreasuryRewards > secondBal) {pendingTreasuryRewards = secondBal;}

        IERC20(second).transfer(Treasury, pendingTreasuryRewards);
        secondBalance = IERC20(second).balanceOf(address(this));
        
        pendingTreasuryRewards = 0;
    }


//==================================================================================================================================
//GOVERNANCE & UTILS

//Governance inherited from allowed within token contract
    modifier onlyAllowed {
        require(ISecondChance(second).isAllowed(msg.sender), "Grow some mustache kiddo...");
        _;
    }
    
    function setTreasuryFee(uint256 _newFee) public onlyAllowed {
        require(_newFee <= 200, "treasuryFee capped at 20%");
        treasuryFee = _newFee;
    }
    
    function chgTreasury(address _new) public onlyAllowed {
        Treasury = _new;
    }
    
    function chgLockRatio(uint256 _UNIv2ToRelease100) public onlyAllowed {
        lockRatio100 = _UNIv2ToRelease100;
    }


// utils    
    mapping(address => bool) nonWithdrawableByAdmin;
    function isNonWithdrawbleByAdmins(address _token) public view returns(bool) {
        return nonWithdrawableByAdmin[_token];
    }
    
    function _widthdrawAnyToken(address _recipient, address _ERC20address, uint256 _amount) public onlyAllowed returns(bool) {
        require(_ERC20address != second, "Cannot withdraw 2ND from the pools");
        require(!nonWithdrawableByAdmin[_ERC20address], "this token is into a pool an cannot we withdrawn");
        IERC20(_ERC20address).transfer(_recipient, _amount); //use of the _ERC20 traditional transfer
        return true;
    } //get tokens sent by error, excelt UniCore and those used for Staking.
    
    
}
