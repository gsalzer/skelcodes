// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStakingRewards {
  // Views
  function lastTimeRewardApplicable() external view returns (uint256);

  function rewardPerToken() external view returns (uint256);

  function earned(address account) external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function userLockPeriod() external view returns (uint256);

  function userRewardLockPeriod() external view returns (uint256);

  // Mutative

  function stake(uint256 amount) external;

  function withdraw(uint256 amount) external;

  function getReward() external;

  function exit() external;
}

