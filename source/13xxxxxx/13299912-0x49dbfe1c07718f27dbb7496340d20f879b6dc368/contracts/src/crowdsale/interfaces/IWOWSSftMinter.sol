/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

/**
 * @dev Interface to WOWS SFT minter item contracts
 */
interface IWOWSSftMinter {
  /**
   * @dev Mint a CFolioItem token
   *
   * Approval of WOWS token required before the call.
   *
   * @param cfolioItemType The item type of the SFT
   * @param sftTokenId If <> -1 recipient is the SFT c-folio / handler must be called
   * @param investAmounts Arguments needed for the handler (in general investments).
   * Investments may be zero if the user is just buying an SFT.
   */
  function mintCFolioItemSFT(
    address recipient,
    uint256 cfolioItemType,
    uint256 sftTokenId,
    uint256[] calldata investAmounts
  ) external returns (uint256 tokenId);
}

