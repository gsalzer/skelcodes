pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title RewardController
 * @author xToken
 *
 * RewardController is the XTK inflationary incentive paid out linearly to stakers via
 * the RewardController. Via team/community consensus and eventually formal governance, XTK
 * inflation is set with an amount and a duration (e.g., 40m XTK for 1 year). At any time, a
 * publicly callable function can release the proportional amount of XTK available since the
 * last call. This function transfers the XTK from the RewardController to the staking module.
 */
contract RewardController is Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    /* ============ State Variables ============ */

    // End time of the active period
    uint256 public periodFinish;
    // Reward amount per sec
    uint256 public rewardRate;
    // Timestamp of the last activity(init, release)
    uint256 public lastUpdateTime;

    // Address of xtk token
    address public constant xtk = 0x7F3EDcdD180Dbe4819Bd98FeE8929b5cEdB3AdEB;
    // Address of Mgmt module
    address public managementStakingModule;

    /* ============ Events ============ */

    event RewardScheduled(uint256 indexed timestamp, uint256 rewardDuration, uint256 rewardAmount);
    event RewardReleased(uint256 indexed timestamp, uint256 amountReleased);

    /* ============ Functions ============ */

    function initialize(address _managementStakingModule) external initializer {
        __Ownable_init();

        managementStakingModule = _managementStakingModule;
    }

    /**
     * Governance function that creates a new release round
     * @param _rewardDuration       Duration of the release round in secs
     * @param _rewardPeriodAmount   Amount of xtk
     */
    function initRewardDurationAndAmount(uint256 _rewardDuration, uint256 _rewardPeriodAmount) external onlyOwner {
        require(block.timestamp >= periodFinish, "Cannot initiate period while reward ongoing");
        require(_rewardDuration > 0, "Invalid reward duration");
        require(_rewardPeriodAmount > 0, "Invalid reward amount");
        require(_rewardPeriodAmount % _rewardDuration == 0, "Amount not multiple of duration");

        rewardRate = _rewardPeriodAmount / _rewardDuration;
        require(rewardRate > 0, "Invalid reward rate");

        uint256 balance = IERC20(xtk).balanceOf(address(this));
        require(_rewardPeriodAmount <= balance, "Reward amount exceeds balance");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + _rewardDuration;

        emit RewardScheduled(block.timestamp, _rewardDuration, _rewardPeriodAmount);
    }

    /**
     * Transfer proportional xtk to Mgmt module
     */
    function releaseReward() external {
        uint256 releasableReward = (lastTimeRewardApplicable() - lastUpdateTime) * rewardRate;
        require(releasableReward > 0, "Releasable reward is zero");

        lastUpdateTime = block.timestamp;
        IERC20(xtk).safeTransfer(managementStakingModule, releasableReward);

        emit RewardReleased(block.timestamp, releasableReward);
    }

    /**
     * Returns Max(block.timestamp, periodFinish)
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp > periodFinish ? periodFinish : block.timestamp;
    }
}

