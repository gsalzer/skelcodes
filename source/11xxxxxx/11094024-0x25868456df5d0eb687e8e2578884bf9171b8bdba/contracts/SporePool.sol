pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

/* 
    Releases spores at the given rate until exhausted
    is doubled or halved every 3,240 blocks (7 days at 20s a block) based on staked $ENOKI
*/
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Defensible.sol";
import "./interfaces/IMushroomFactory.sol";
import "./interfaces/IMission.sol";
import "./SporeToken.sol";
import "./ApprovedContractList.sol";

contract SporePool is Ownable, ReentrancyGuard, Pausable, Defensible {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    SporeToken public rewardsToken;
    IERC20 public stakingToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 7 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    uint256 public constant MAX_PERCENTAGE = 100;
    uint256 public devRewardPercentage;
    address public devRewardAddress;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    IMushroomFactory public mushroomFactory;
    IMission public mission;
    ApprovedContractList public approvedContractList;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _owner,
        address _rewardsToken,
        address _stakingToken,
        address _mushroomFactory,
        address _mission,
        address _approvedContractList,
        uint256 _devRewardPercentage,
        address _devRewardAddress
    ) public {
        rewardsToken = SporeToken(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        mushroomFactory = IMushroomFactory(_mushroomFactory);
        mission = IMission(_mission);
        approvedContractList = ApprovedContractList(_approvedContractList);

        devRewardPercentage = _devRewardPercentage;
        devRewardAddress = _devRewardAddress;
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored.add(lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply));
    }

    function earned(address account) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) external nonReentrant defend(approvedContractList) whenNotPaused updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function harvest(uint256 mushroomsToGrow) public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];

        if (reward > 0) {
            uint256 remainingReward = reward;
            rewards[msg.sender] = 0;

            // Burn some rewards for mushrooms if desired
            if (mushroomsToGrow > 0) {
                uint256 totalCost = mushroomFactory.costPerMushroom().mul(mushroomsToGrow);
                require(reward >= totalCost, "Not enough rewards to grow the number of mushrooms specified");

                uint256 toDev = totalCost.mul(devRewardPercentage).div(MAX_PERCENTAGE);
                rewardsToken.burn(totalCost.sub(toDev));

                if (toDev > 0) {
                    mission.sendSpores(devRewardAddress, toDev);
                }

                remainingReward = reward.sub(totalCost);
                mushroomFactory.growMushrooms(msg.sender, mushroomsToGrow);
            }

            if (remainingReward > 0) {
                // TODO: Add safe ERC20 features to spore token
                // rewardsToken.safeTransfer(msg.sender, remainingReward);

                mission.sendSpores(msg.sender, remainingReward);
                emit RewardPaid(msg.sender, remainingReward);
            }
        }
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        harvest(0);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward) external onlyOwner updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        // Cannot recover the staking token or the rewards token
        require(tokenAddress != address(stakingToken) && tokenAddress != address(rewardsToken), "Cannot withdraw the staking or rewards tokens");

        //TODO: Add safeTransfer
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(block.timestamp > periodFinish, "Previous rewards period must be complete before changing the duration for the new period");
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
}

