/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity 0.7.6;

interface IRewardHandler {
  /**
   * @dev Get the amount allocated for the Booster
   *
   * @return The amount which is allocated for the Booster (18 decimals)
   */
  function getBoosterRewards() external view returns (uint256);

  /**
   * @dev Transfer reward and distribute the fee
   *
   * This is the new implementation of distribute() which uses internal fees
   * defined in the {RewardHandler} contract.
   *
   * @param recipient The recipient of the reward
   * @param amount The amount of WOWS to transfer to the recipient
   * @param fee The reward fee in 1e6 factor notation
   */
  function distribute2(
    address recipient,
    uint256 amount,
    uint32 fee
  ) external;

  /**
   * @dev Transfer reward and distribute the fee
   *
   * This is the current implementation, needed for backward compatibility.
   *
   * Current ERC1155Minter and Controller call this function, later
   * reward handler clients should call the the new one with internal
   * fees specified in this contract.
   *
   * uint32 values are in 1e6 factor notation.
   */
  function distribute(
    address recipient,
    uint256 amount,
    uint32 fee,
    uint32 toTeam,
    uint32 toMarketing,
    uint32 toBooster,
    uint32 toRewardPool
  ) external;
}

