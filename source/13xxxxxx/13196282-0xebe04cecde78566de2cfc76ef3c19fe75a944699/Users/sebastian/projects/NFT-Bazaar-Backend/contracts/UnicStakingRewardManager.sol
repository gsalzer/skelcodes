pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "./interfaces/IRewardable.sol";
import "./abstract/EmergencyWithdrawable.sol";

contract UnicStakingRewardManager is Initializable, EmergencyWithdrawable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 private constant MAX_INT = 2**256 - 1;
    uint256 private constant DIV_PRECISION = 1e18;

    struct RewardPool {
        IERC20Upgradeable rewardToken;
        address creator;
        uint256 startTime;
        uint256 endTime;
        uint256 amount;
        uint256 id;
    }

    // incremental counter for all pools
    uint256 public poolCounter;

    // the staking pool that should receive rewards from the pools later on
    IRewardable public stakingPool;

    // using the counter as the key
    mapping(uint256 => RewardPool) public rewardPools;
    mapping(address => RewardPool[]) public rewardPoolsByToken;

    event RewardPoolAdded(address indexed rewardToken, address indexed creator, uint256 poolId, uint256 amount);

    function initialize(
        IRewardable _stakingPool
    ) public initializer {
        __Ownable_init();
        stakingPool = _stakingPool;
    }

    function addRewardPool(IERC20Upgradeable rewardToken, uint256 startTime, uint256 endTime, uint256 amount) external onlyOwner {
        require(startTime > block.timestamp, "Start time should be in the future");
        require(endTime > startTime, "End time must be after start time");

        rewardToken.approve(address(stakingPool), MAX_INT);
        rewardToken.safeTransferFrom(msg.sender, address(this), amount);
        poolCounter = poolCounter.add(1);

        RewardPool memory pool = RewardPool({
            creator: msg.sender,
            rewardToken: rewardToken,
            startTime: startTime,
            endTime: endTime,
            amount: amount,
            id: poolCounter
        });

        rewardPools[poolCounter] = pool;
        emit RewardPoolAdded(address(rewardToken), msg.sender, poolCounter, amount);
    }

    function distributeRewards(uint256 poolId) public {
        RewardPool storage pool = rewardPools[poolId];
        require(pool.startTime < block.timestamp, "Pool not started");
        require(pool.amount > 0, "Pool fully distributed");

        uint256 vestedForDistribution = pool.endTime.sub(block.timestamp).mul(DIV_PRECISION).div((pool.endTime.sub(pool.startTime))).mul(pool.amount).div(DIV_PRECISION);
        pool.amount = pool.amount.sub(vestedForDistribution);

        // if we don't have enough balance on the contract, we just distribute what we have
        if (pool.rewardToken.balanceOf(address(this)) < vestedForDistribution) {
            vestedForDistribution = pool.rewardToken.balanceOf(address(this));
        }

        // the staking pool only knows
        if (vestedForDistribution > 0) {
            stakingPool.addRewards(address(pool.rewardToken), vestedForDistribution);
        }
    }
}

