// SPDX-License-Identifier: WHO GIVES A FUCK ANYWAY??
// but thanks a million Gwei to MIT and Zeppelin. You guys rock!!!

// MAINNET VERSION.

pragma solidity ^0.6.6;

import "./UniCore_Libraries.sol";
import "./UniCore_Interfaces.sol";


// Vault distributes fees equally amongst staked pools

contract UniCore_Vault {
    using SafeMath for uint256;


    address public UniCore; //token address
    
    address public Treasury1;
    address public Treasury2;
    address public Treasury3;
    uint256 public treasuryFee;
    uint256 public pendingTreasuryRewards;
    

//USERS METRICS
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 rewardPaid; // Already Paid. See explanation below.
        //  pending reward = (user.amount * pool.UniCorePerShare) - user.rewardPaid
    }
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    
//POOL METRICS
    struct PoolInfo {
        address stakedToken;                // Address of staked token contract.
        uint256 allocPoint;           // How many allocation points assigned to this pool. UniCores to distribute per block. (ETH = 2.3M blocks per year)
        uint256 accUniCorePerShare;   // Accumulated UniCores per share, times 1e18. See below.
        bool withdrawable;            // Is this pool withdrawable or not
        
        mapping(address => mapping(address => uint256)) allowance;
    }
    PoolInfo[] public poolInfo;

    uint256 public totalAllocPoint;     // Total allocation points. Must be the sum of all allocation points in all pools.
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
    constructor(address _UniCore) public {

        UniCore = _UniCore;
        
        Treasury1 = address(0x688C3eE6E470b63a4Edfc9A798908b473B5CaA93); // UniCore Central
        Treasury2 = address(0x58071aeb3e5550A9359efBff98b7eCF59057799d); //stpd 
        Treasury3 = address(0x05957F3344255fDC9fE172E30016ee148D684313); //QS 
        
        treasuryFee = 700; //7%
        
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
    function addPool( uint256 _allocPoint, address _stakedToken, bool _withdrawable) public governanceLevel(2) {
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
                accUniCorePerShare: 0,
                withdrawable : _withdrawable
            })
        );
    }

    // Updates the given pool's  allocation points. Can only be called with right governance levels.
    function setPool(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public governanceLevel(2) {
        require(_allocPoint > 0, "Zero alloc points not allowed");
        if (_withUpdate) {massUpdatePools();}

        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Update the given pool's ability to withdraw tokens
    function setPoolWithdrawable(uint256 _pid, bool _withdrawable) public governanceLevel(2) {
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
    function updatePool(uint256 _pid) internal returns (uint256 UniCoreRewardWhole) {
        PoolInfo storage pool = poolInfo[_pid];

        uint256 tokenSupply = IERC20(pool.stakedToken).balanceOf(address(this));
        if (tokenSupply == 0) { // avoids division by 0 errors
            return 0;
        }
        UniCoreRewardWhole = pendingRewards     // Multiplies pending rewards by allocation point of this pool and then total allocation
            .mul(pool.allocPoint)               // getting the percent of total pending rewards this pool should get
            .div(totalAllocPoint);              // we can do this because pools are only mass updated
        
        uint256 UniCoreRewardFee = UniCoreRewardWhole.mul(treasuryFee).div(10000);
        uint256 UniCoreRewardToDistribute = UniCoreRewardWhole.sub(UniCoreRewardFee);

        pendingTreasuryRewards = pendingTreasuryRewards.add(UniCoreRewardFee);

        pool.accUniCorePerShare = pool.accUniCorePerShare.add(UniCoreRewardToDistribute.mul(1e18).div(tokenSupply));
    }
    function massUpdatePools() public {
        uint256 length = poolInfo.length; 
        uint allRewards;
        
        for (uint256 pid = 0; pid < length; ++pid) {
            allRewards = allRewards.add(updatePool(pid)); //calls updatePool(pid)
        }
        pendingRewards = pendingRewards.sub(allRewards);
    }
    
    //payout of UniCore Rewards, uses SafeUnicoreTransfer
    function updateAndPayOutPending(uint256 _pid, address user) internal {
        
        massUpdatePools();

        uint256 pending = pendingUniCore(_pid, user);

        safeUniCoreTransfer(user, pending);
    }
    
    
    // Safe UniCore transfer function, Manages rounding errors.
    function safeUniCoreTransfer(address _to, uint256 _amount) internal {
        if(_amount == 0) return;

        uint256 UniCoreBal = IERC20(UniCore).balanceOf(address(this));
        if (_amount >= UniCoreBal) { IERC20(UniCore).transfer(_to, UniCoreBal);} 
        else { IERC20(UniCore).transfer(_to, _amount);}

        transferTreasuryFees(); //adds unecessary gas for users, team can trigger the function manually
        UniCoreBalance = IERC20(UniCore).balanceOf(address(this));
    }

//external call from token when rewards are loaded

    /* @dev called by the token after each fee transfer to the vault.
    *       updates the pendingRewards and the rewardsInThisEpoch variables
    */      
    modifier onlyUniCore() {
        require(msg.sender == UniCore);
        _;
    }
    
    uint256 private UniCoreBalance;
    function updateRewards() external onlyUniCore {  //function addPendingRewards(uint256 _) for CORE
        uint256 newRewards = IERC20(UniCore).balanceOf(address(this)).sub(UniCoreBalance); //delta vs previous balanceOf

        if(newRewards > 0) {
            UniCoreBalance =  IERC20(UniCore).balanceOf(address(this)); //balance snapshot
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
        lastTXBlock[msg.sender] = block.number;
        
        require(_amount > 0, "cannot deposit zero tokens");
        
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updateAndPayOutPending(_pid, msg.sender); //Transfer pending tokens, updates the pools 

        //Transfer the amounts from user
        IERC20(pool.stakedToken).transferFrom(msg.sender, address(this), _amount);
        user.amount = user.amount.add(_amount);

        //Finalize
        user.rewardPaid = user.amount.mul(pool.accUniCorePerShare).div(1e18);
        
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw tokens from Vault.
    function withdraw(uint256 _pid, uint256 _amount) external NoReentrant(msg.sender) {
        lastTXBlock[msg.sender] = block.number;
        _withdraw(_pid, _amount, msg.sender, msg.sender);
        transferTreasuryFees(); //incurs a gas penalty -> treasury fees transfer
        IUniCore(UniCore).burnFromUni(_amount); //performs the burn on UniSwap pool
    }
    function _withdraw(uint256 _pid, uint256 _amount, address from, address to) internal {

        PoolInfo storage pool = poolInfo[_pid];
        require(pool.withdrawable, "Withdrawing from this pool is disabled");
        
        UserInfo storage user = userInfo[_pid][from];
        require(user.amount >= _amount, "withdraw: user amount insufficient");

        updateAndPayOutPending(_pid, from); // //Transfer pending tokens, massupdates the pools 

        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            IERC20(pool.stakedToken).transfer(address(to), _amount);
        }
        user.rewardPaid = user.amount.mul(pool.accUniCorePerShare).div(1e18);

        emit Withdraw(to, _pid, _amount);
    }

    // Getter function to see pending UniCore rewards per user.
    function pendingUniCore(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accUniCorePerShare = pool.accUniCorePerShare;

        return user.amount.mul(accUniCorePerShare).div(1e18).sub(user.rewardPaid);
    }

//==================================================================================================================================
//TREASURY 

    function transferTreasuryFees() public {
        if(pendingTreasuryRewards == 0) return;

        uint256 UniCorebal = IERC20(UniCore).balanceOf(address(this));
        
        //splitRewards
        uint256 rewards3 = pendingTreasuryRewards.mul(19).div(100); //stpd
        uint256 rewards2 = pendingTreasuryRewards.mul(19).div(100); //qtsr
        uint256 rewards1 = pendingTreasuryRewards.sub(rewards3).sub(rewards2); //team -> could
        
        
        //manages overflows or bad math
        if (pendingTreasuryRewards > UniCorebal) {
            rewards3 = UniCorebal.mul(19).div(100); //stpd
            rewards2 = UniCorebal.mul(19).div(100); //qtsr
            rewards1 = UniCorebal.sub(rewards3).sub(rewards2); //team
        } 

            IERC20(UniCore).transfer(Treasury3, rewards3);
            IERC20(UniCore).transfer(Treasury2, rewards2);
            IERC20(UniCore).transfer(Treasury1, rewards1);

            UniCoreBalance = IERC20(UniCore).balanceOf(address(this));
        
            pendingTreasuryRewards = 0;
    }


//==================================================================================================================================
//GOVERNANCE & UTILS

//Governance inherited from governance levels of UniCoreVaultAddress
    function viewGovernanceLevel(address _address) public view returns(uint8) {
        return IUniCore(UniCore).viewGovernanceLevel(_address);
    }
    
    modifier governanceLevel(uint8 _level){
        require(viewGovernanceLevel(msg.sender) >= _level, "Grow some mustache kiddo...");
        _;
    }
    
    function setTreasuryFee(uint256 _newFee) public governanceLevel(2) {
        require(_newFee <= 150, "treasuryFee capped at 15%");
        treasuryFee = _newFee;
    }
    
    function chgTreasury1(address _new) public {
        require(msg.sender == Treasury1, "Treasury holder only");
        Treasury1 = _new;
    }
    function chgTreasury2(address _new) public {
        require(msg.sender == Treasury2, "Treasury holder only");
        Treasury2 = _new;
    }
    function chgTreasury3(address _new) public {
        require(msg.sender == Treasury3, "Treasury holder only");
        Treasury3 = _new;
    }

// utils    
    mapping(address => bool) nonWithdrawableByAdmin;
    function isNonWithdrawbleByAdmins(address _token) public view returns(bool) {
        return nonWithdrawableByAdmin[_token];
    }
    function _widthdrawAnyToken(address _recipient, address _ERC20address, uint256 _amount) public governanceLevel(2) returns(bool) {
        require(_ERC20address != UniCore, "Cannot withdraw Unicore from the pools");
        require(!nonWithdrawableByAdmin[_ERC20address], "this token is into a pool an cannot we withdrawn");
        IERC20(_ERC20address).transfer(_recipient, _amount); //use of the _ERC20 traditional transfer
        return true;
    } //get tokens sent by error, excelt UniCore and those used for Staking.
    
    
}

