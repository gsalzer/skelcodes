/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

/**
 * @notice Cryptofolio and tokenId interface
 */
interface ITradeFloor {
  //////////////////////////////////////////////////////////////////////////////
  // Getters
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Return all tokenIds owned by account
   */
  function getTokenIds(address account)
    external
    view
    returns (uint256[] memory);
}

