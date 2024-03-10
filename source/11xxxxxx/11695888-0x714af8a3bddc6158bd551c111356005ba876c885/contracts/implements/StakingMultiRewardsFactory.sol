// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./StakingMultiRewards.sol";
import "../interfaces/IEmergency.sol";

contract StakingMultiRewardsFactory is Ownable, IEmergency {
    using SafeMath for uint256;

    // immutables
    address public emergencyRecipient;
    address public rewardsToken;
    address public bonusToken;
    uint256 public stakingRewardsGenesis;
    uint256 public rewardsDuration;

    // the staking tokens for which the rewards contract has been deployed
    address[] public stakingTokens;

    // info about rewards for a particular staking token
    struct StakingMultiRewardsInfo {
        address stakingRewards;
        uint256 rewardAmount;
        uint rewardsRatioBps;
    }

    // rewards info by staking token
    mapping(address => StakingMultiRewardsInfo) public stakingRewardsInfoByStakingToken;

    constructor(
        address _owner,
        address _emergencyRecipient,
        address _rewardsToken,
        address _bonusToken,
        uint256 _stakingRewardsGenesis,
        uint256 _rewardsDuration
    ) Ownable(_owner) {
        require(_stakingRewardsGenesis >= block.timestamp, "genesis too soon");
        require(_rewardsDuration > 0, "rewards duration is zero");

        emergencyRecipient = _emergencyRecipient;

        rewardsToken = _rewardsToken;
        bonusToken = _bonusToken;
        stakingRewardsGenesis = _stakingRewardsGenesis;
        rewardsDuration = _rewardsDuration;
    }

    function emergencyWithdraw(IERC20 token) external override {
        require(
            address(token) != address(rewardsToken) &&
            address(token) != address(bonusToken), "forbidden token");

        token.transfer(emergencyRecipient, token.balanceOf(address(this)));
    }

    // call notifyRewardAmount for all staking tokens.
    function notifyRewardAmounts() external {
        require(stakingTokens.length > 0, "called before any deploys");
        for (uint i = 0; i < stakingTokens.length; i++) {
            notifyRewardAmount(stakingTokens[i]);
        }
    }

    // notify reward amount for an individual staking token.
    // this is a fallback in case the notifyRewardAmounts costs too much gas to call for all contracts
    function notifyRewardAmount(address stakingToken) public {
        require(block.timestamp >= stakingRewardsGenesis, "not ready");

        StakingMultiRewardsInfo storage info = stakingRewardsInfoByStakingToken[stakingToken];
        require(info.stakingRewards != address(0), "not deployed");

        if (info.rewardAmount > 0) {
            uint256 rewardAmount0 = info.rewardAmount;
            info.rewardAmount = 0;
            uint256 rewardAmount1 = rewardAmount0.mul(info.rewardsRatioBps).div(10000);

            require(
                IERC20(rewardsToken).transfer(info.stakingRewards, rewardAmount0)
                && IERC20(bonusToken).transfer(info.stakingRewards, rewardAmount1),
                "transfer failed"
            );
            StakingMultiRewards(info.stakingRewards).notifyRewardAmount(rewardAmount0);
        }
    }

    // deploy a staking reward contract for the staking token, and store the reward amount
    // the reward will be distributed to the staking reward contract no sooner than the genesis
    function deploy(address stakingToken, uint256 rewardAmount, uint rewardsRatioBps) external onlyOwner {
        require(rewardsRatioBps > 0 && rewardsRatioBps <= 10000, "ratio bps must be greater than 0 and less-eq than 10000");
        StakingMultiRewardsInfo storage info = stakingRewardsInfoByStakingToken[stakingToken];
        require(info.stakingRewards == address(0), "already deployed");

        info.stakingRewards = address(
            new StakingMultiRewards(emergencyRecipient, address(this), rewardsToken, bonusToken, rewardsRatioBps, stakingToken, rewardsDuration));
        info.rewardAmount = rewardAmount;
        info.rewardsRatioBps = rewardsRatioBps;
        stakingTokens.push(stakingToken);

        emit StakingRewardsDeployed(info.stakingRewards, stakingToken, rewardAmount);
    }

    event StakingRewardsDeployed(address indexed stakingRewards, address indexed stakingToken, uint256 rewardAmount);
}

