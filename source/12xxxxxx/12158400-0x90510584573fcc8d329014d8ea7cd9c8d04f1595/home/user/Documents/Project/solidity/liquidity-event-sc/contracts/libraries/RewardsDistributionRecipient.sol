// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.6 <0.9.0;


abstract contract RewardsDistributionRecipient {
    address public rewardsDistribution;

    function notifyRewardAmount(uint256 reward) external virtual;

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "!rewardsDistribution");
        _;
    }
}

