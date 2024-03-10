/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.6.0 <0.8.0;

interface IFarm {
  /**
   * @dev Return a unique farm name
   */
  function farmName() external view returns (string memory);

  /**
   * @dev Return when reward period is finished (UTC timestamp)
   */
  function periodFinish() external view returns (uint256);

  /**
   * @dev Sets a new controller, can only called by current controller
   */
  function setController(address newController) external;

  /**
   * @dev This function must be called initially and close at the time the
   * reward period ends
   */
  function notifyRewardAmount(uint256 reward) external;

  /**
   * @dev Set the duration of farm rewards, to continue rewards,
   * notifyRewardAmount() has to called for the next period
   */
  function setRewardsDuration(uint256 _rewardsDuration) external;

  /**
   * @dev Rebalance strategies (if implemented)
   */
  function rebalance() external;
}

