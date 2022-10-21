/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.6.0 <0.8.0;

interface IController {
  /**
   * @dev Revert on failure, return deposit fee in 1e-18/fee notation on success
   */
  function onDeposit(uint256 amount) external view returns (uint256 fee);

  /**
   * @dev Revert on failure, return withdrawal fee in 1e-18/fee notation on success
   */
  function onWithdraw(uint256 amount) external view returns (uint256 fee);

  /**
   * @dev Distribute rewards to sender and fee to internal contracts
   */
  function payOutRewards(address recipient, uint256 amount) external;
}

