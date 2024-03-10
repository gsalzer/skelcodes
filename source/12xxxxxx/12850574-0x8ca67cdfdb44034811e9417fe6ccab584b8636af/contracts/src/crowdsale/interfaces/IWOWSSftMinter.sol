/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ICFolioFarm
 *
 * @dev ICFolioFarm is the business logic interface to c-folio farms.
 */
interface IWOWSSftMinter {
  /**
   * @dev Calculate a 128 bit hash for making tokenIds unique to nderlying asset
   *
   * @param sftTokenId The tokenId from SFT contract from that we use the first 128 bit
   * TokenIds in SFT contract are limited to max 128 Bit in WowsSftMinter contract.
   */
  function tradeFloorTokenId(uint256 sftTokenId)
    external
    view
    returns (uint256);
}

