/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

/**
 * @dev Interface to C-folio item contracts
 */
interface IBooster {
  /**
   * @dev return current rewardHandler
   */
  function rewardHandler() external view returns (address);

  /**
   * @dev return current sftHolder
   */
  function sftHolder() external view returns (address);

  /**
   * @dev Return information about the reward state in Booster
   *
   * @param tokenIds The SFT or TF tokenId
   *
   * @return locked The total amounts locked
   * @return pending The pending amounts claimable
   * @return apr The APR of this lock pool
   * @return secsLeft Numbers of seconds until unlock, or -1 if unlocked
   */
  function getRewardInfo(uint256[] calldata tokenIds)
    external
    view
    returns (
      uint256[] memory locked,
      uint256[] memory pending,
      uint256[] memory apr,
      uint256[] memory secsLeft
    );

  /**
   * @dev Create a booster pool from v1 specs
   *
   * @param tokenId The SFT tokenId
   * @param data list of uint256's: total, pending, provided, apr, end, fee
   */
  function migrateCreatePool(
    uint256 tokenId,
    bytes memory data,
    uint256 dataIndex
  ) external returns (uint256);

  /**
   * @dev Handles farm distribution, only callable from controller
   *
   * If recipient is booster contract, amount is temporarily stored and locked
   * in a second call.
   *
   * @param farm The reward farm that the call originates from
   * @param recipient The recipient of the rewards
   * @param amount The amount to distribute
   * @param fee The fee in 6 decimal notation
   */
  function distributeFromFarm(
    address farm,
    address recipient,
    uint256 amount,
    uint32 fee
  ) external;

  /**
   * @dev Locks temporary tokens owned by recipient for a specific duration
   * of seconds.
   *
   * @param recipient The recipient of the rewards
   * @param lockPeriod The lock period in seconds
   */
  function lock(address recipient, uint256 lockPeriod) external;

  /**
   * @dev Claim rewards either into wallet or re-lock them
   *
   * @param sftTokenId The tokenId that manages the rewards
   * @param reLock True to re-lock existing rewards to earn more
   */
  function claimRewards(uint256 sftTokenId, bool reLock) external;

  /**
   * @dev Set sftHolder contract which is deployed after Booster
   */
  function setSftHolder(address sftHolder_) external;

  /**
   * @dev Set reward handler in case it will be upgraded
   */
  function setRewardHandler(address rewardHandler_) external;
}

