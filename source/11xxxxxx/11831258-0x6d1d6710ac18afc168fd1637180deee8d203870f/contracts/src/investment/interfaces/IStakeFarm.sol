/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title IStakeFarm
 *
 * @dev IStakeFarm is the business logic interface to staking farms.
 */

interface IStakeFarm {
  /**
   * @dev Stake amount of ERC20 tokens and earn rewards
   */
  function stake(uint256 amount) external;

  /**
   * @dev Unstake amount of previous staked tokens, rewards will not be claimed
   */
  function unstake(uint256 amount) external;

  /**
   * @dev Claim rewards harvested during stake time
   */
  function getReward() external;

  /**
   * @dev Unstake and getRewards in a single step
   */
  function exit() external;

  /**
   * @dev Transfer amount of stake from msg.sender to recipient.
   */
  function transfer(address recipient, uint256 amount) external;
}

