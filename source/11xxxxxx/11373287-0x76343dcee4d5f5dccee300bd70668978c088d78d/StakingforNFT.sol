pragma solidity ^0.5.16;

import "./StakingHelpersNFT.sol";


contract StakingForNFT is IStakingForNFT, RewardsDistributionRecipient, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken1;
    IERC20 public rewardsToken2;
    IERC20 public rewardsToken3;

    IERC20 public stakingToken;
    IERC20 public stakingTokenMultiplier;

    uint256 public periodFinish = 0;
    uint256 public locktime = 2 days;
    
    uint256 public rewardRate1 = 0;
    uint256 public rewardRate2 = 0;
    uint256 public rewardRate3 = 0;

    uint256 public rewardsDuration = 30 days;//2 weeks
    uint256 public lastUpdateTime;
    uint256 public rewardPerToken1Stored;
    uint256 public rewardPerToken2Stored;
    uint256 public rewardPerToken3Stored;

    mapping(address => uint256) public userRewardPerToken1Paid;
    mapping(address => uint256) public userRewardPerToken2Paid;
    mapping(address => uint256) public userRewardPerToken3Paid;

    mapping(address => uint256) public rewards1;
    mapping(address => uint256) public rewards2;
    mapping(address => uint256) public rewards3;

    uint256 private _totalSupply;
    uint256 private _totalSupplyMultiplier;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _balancesMultiplier;
    
    mapping(address => uint256) public lockingPeriodMultiplier;
    mapping(address => uint256) public multiplierFactor;


    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _owner,
        address _rewardsDistribution,
        address _rewardsToken1,
        address _rewardsToken2,
        address _rewardsToken3,
        address _stakingToken,
        address _stakingTokenMultiplier
    ) public Owned(_owner) {
        rewardsToken1 = IERC20(_rewardsToken1);
        rewardsToken2 = IERC20(_rewardsToken2);
        rewardsToken3 = IERC20(_rewardsToken3);
        stakingToken = IERC20(_stakingToken);
        stakingTokenMultiplier = IERC20(_stakingTokenMultiplier);
        rewardsDistribution = _rewardsDistribution;
    }

    /* ========== VIEWS ========== */
    
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function totalSupplyMultiplier() external view returns (uint256) {
        return _totalSupplyMultiplier;
    }

    function balanceOfMultiplier(address account) external view returns (uint256) {
        return _balancesMultiplier[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken1() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerToken1Stored;
        }
        return
            rewardPerToken1Stored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate1).mul(1e18).div(_totalSupply)
            );
    }
    
    function rewardPerToken2() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerToken2Stored;
        }
        return
            rewardPerToken2Stored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate2).mul(1e18).div(_totalSupply)
            );
    }
    
    function rewardPerToken3() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerToken3Stored;
        }
        return
            rewardPerToken3Stored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate3).mul(1e18).div(_totalSupply)
            );
    }
    
    function getMultiplyingFactor(address account) public view returns (uint256) {
        if (multiplierFactor[account] == 0) {
            return 1e18;
        }
        return
            multiplierFactor[account];
    }

    function earnedtoken1(address account) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken1().sub(userRewardPerToken1Paid[account])).mul(getMultiplyingFactor(account))
        .div(1e18).div(1e18).add(rewards1[account]);
    }
    
    function earnedtoken2(address account) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken2().sub(userRewardPerToken2Paid[account])).mul(getMultiplyingFactor(account))
        .div(1e18).div(1e18).add(rewards2[account]);
    }
    
    function earnedtoken3(address account) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken3().sub(userRewardPerToken3Paid[account])).mul(getMultiplyingFactor(account))
        .div(1e18).div(1e18).add(rewards3[account]);
    }

    function getReward1ForDuration() external view returns (uint256) {
        return rewardRate1.mul(rewardsDuration);
    }

    function getReward2ForDuration() external view returns (uint256) {
        return rewardRate2.mul(rewardsDuration);
    }

    function getReward3ForDuration() external view returns (uint256) {
        return rewardRate3.mul(rewardsDuration);
    }


    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) external nonReentrant notPaused updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        
        //NOTE: SERGS contract has 2.5% fees....
        uint256 feeamount=amount.div(40);
        uint256 remamount=amount.sub(feeamount);

        _totalSupply = _totalSupply.add(remamount);
        _balances[msg.sender] = _balances[msg.sender].add(remamount);
        
        // SERGS contract will send balance cutting 2.5% fees
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function stakeMultiplier(uint256 amount) external nonReentrant notPaused getTotalMultiplier(msg.sender, amount){
        require(amount > 0, "Cannot stake 0");
        lockingPeriodMultiplier[msg.sender]= block.timestamp.add(locktime);

        _totalSupplyMultiplier = _totalSupplyMultiplier.add(amount);
        _balancesMultiplier[msg.sender] = _balancesMultiplier[msg.sender].add(amount);
        stakingTokenMultiplier.safeTransferFrom(msg.sender, address(this), amount);
        emit StakedMultiplier(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");

        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function withdrawMultiplier(uint256 amount) public nonReentrant {
        require(amount > 0, "Cannot withdraw 0");
        require(block.timestamp >= lockingPeriodMultiplier[msg.sender], "Transaction hasn't surpassed time lock.");

        _totalSupplyMultiplier = _totalSupplyMultiplier.sub(amount);
        _balancesMultiplier[msg.sender] = _balancesMultiplier[msg.sender].sub(amount);
        stakingTokenMultiplier.safeTransfer(msg.sender, amount);
        emit WithdrawnMultiplier(msg.sender, amount);
    }

    function getReward() public payable nonReentrant updateReward(msg.sender) {
        uint256 reward1 = rewards1[msg.sender];
        uint256 reward2 = rewards2[msg.sender];
        uint256 reward3 = rewards3[msg.sender];
        
        if (reward1 > 0) {
            // mint tokens to be used for farming
            rewardsToken1.mintToFarm(reward1);
            rewards1[msg.sender] = 0;
            rewardsToken1.safeTransfer(msg.sender, reward1);
        }
        if (reward2 > 0) {
            // mint tokens to be used for farming
            rewardsToken2.mintToFarm(reward2);
            rewards2[msg.sender] = 0;
            rewardsToken2.safeTransfer(msg.sender, reward2);
        }
        if (reward3 > 0) {
            // mint tokens to be used for farming
            rewardsToken3.mintToFarm(reward3);
            rewards3[msg.sender] = 0;
            rewardsToken3.safeTransfer(msg.sender, reward3);
        }
        emit RewardPaid(msg.sender, reward1, reward2, reward3);
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        withdrawMultiplier(_balancesMultiplier[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    //YOU>JUST>WIN
    function notifyRewardAmount(uint256 reward1, uint256 reward2, uint256 reward3) external onlyRewardsDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate1 = reward1.div(rewardsDuration);
            rewardRate2 = reward2.div(rewardsDuration);
            rewardRate3 = reward3.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover1 = remaining.mul(rewardRate1);
            rewardRate1 = reward1.add(leftover1).div(rewardsDuration);
            uint256 leftover2 = remaining.mul(rewardRate2);
            rewardRate2 = reward2.add(leftover2).div(rewardsDuration);
            uint256 leftover3 = remaining.mul(rewardRate3);
            rewardRate3 = reward3.add(leftover3).div(rewardsDuration);
        }
        
        
        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        // uint balance1 = reward1;//rewardsToken.balanceOf(address(this));
        // require(rewardRate1 <= reward1.div(rewardsDuration), "Provided reward too high");

        // // uint balance2 = reward2;//rewardsToken.balanceOf(address(this));
        // require(rewardRate2 <= reward2.div(rewardsDuration), "Provided reward too high");

        // // uint balance3 = reward3;//rewardsToken.balanceOf(address(this));
        // require(rewardRate3 <= reward3.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
    }

    // // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        // // If it's SNX we have to query the token symbol to ensure its not a proxy or underlying
        // bool isSNX = (keccak256(bytes("SNX")) == keccak256(bytes(ERC20Detailed(tokenAddress).symbol())));
        // // Cannot recover the staking token or the rewards token
        // require(
        //     tokenAddress != address(stakingToken) && tokenAddress != address(rewardsToken) && !isSNX,
        //     "Cannot withdraw the staking or rewards tokens"
        // );
        IERC20(tokenAddress).safeTransfer(owner, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }
    
        /* ========== MODIFIERS ========== */


     modifier getTotalMultiplier(address account, uint256 balance) {
        uint256 multiplier=0;
        if(balance>0 && balance <= 5*10 ** 18) {
            multiplier = balance.mul(10).div(100);
        }
        else if(balance>5*10 ** 18){
            multiplier = 5*10**17;
        }
         uint256 multiplyFactor = multiplier.add(1*10**18);
         multiplierFactor[msg.sender]=multiplyFactor;
        _;
    }

    

    modifier updateReward(address account) {
        rewardPerToken1Stored = rewardPerToken1();
        rewardPerToken2Stored = rewardPerToken2();
        rewardPerToken3Stored = rewardPerToken3();

        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards1[account] = earnedtoken1(account);
            userRewardPerToken1Paid[account] = rewardPerToken1Stored;
            rewards2[account] = earnedtoken2(account);
            userRewardPerToken2Paid[account] = rewardPerToken2Stored;
            rewards3[account] = earnedtoken3(account);
            userRewardPerToken3Paid[account] = rewardPerToken3Stored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event StakedMultiplier(address indexed user, uint256 amount);
    
    event Withdrawn(address indexed user, uint256 amount);
    event WithdrawnMultiplier(address indexed user, uint256 amount);

    event RewardPaid(address indexed user, uint256 reward1, uint256 reward2, uint256 reward3);

    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
}




