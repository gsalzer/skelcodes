// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.0;

interface IRewardPool {
  function addMarginalReward(address rewardToken) external returns (uint256);
}
