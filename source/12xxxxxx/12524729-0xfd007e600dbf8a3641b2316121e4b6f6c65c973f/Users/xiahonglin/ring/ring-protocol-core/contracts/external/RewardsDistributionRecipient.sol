// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

abstract contract RewardsDistributionRecipient {
    address public rewardsDistribution;

    function notifyRewardAmount(uint256 reward) external virtual;

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "Caller is not RewardsDistribution contract");
        _;
    }
}
