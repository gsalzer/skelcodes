/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

contract ERC20Recovery {
  using SafeERC20 for IERC20;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Fired when a recipient receives recovered ERC-20 tokens
   *
   * @param recipient The target recipient receving the recovered coins
   * @param tokenAddress The address of the ERC-20 token
   * @param tokenAmount The amount of the token being recovered
   */
  event Recovered(
    address indexed recipient,
    address indexed tokenAddress,
    uint256 tokenAmount
  );

  //////////////////////////////////////////////////////////////////////////////
  // Internal interface
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Recover ERC20 token from contract which have been transfered
   * either by accident or via airdrop
   *
   * Proper access must be verified. All tokens used by the system must
   * be blocked from recovery.
   *
   * @param recipient The target recipient of the recovered coins
   * @param tokenAddress The address of the ERC-20 token
   * @param tokenAmount The amount of the token to recover
   */
  function _recoverERC20(
    address recipient,
    address tokenAddress,
    uint256 tokenAmount
  ) internal {
    // Validate parameters
    require(recipient != address(0), "Can't recover to address 0");

    // Update state
    IERC20(tokenAddress).safeTransfer(recipient, tokenAmount);

    // Dispatch event
    emit Recovered(recipient, tokenAddress, tokenAmount);
  }
}

