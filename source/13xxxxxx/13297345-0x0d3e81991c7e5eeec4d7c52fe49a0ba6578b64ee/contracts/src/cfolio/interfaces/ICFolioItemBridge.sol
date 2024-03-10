/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

/**
 * @dev Interface to C-folio item bridge
 */
interface ICFolioItemBridge {
  /**
   * @notice Send multiple types of tokens from the _from address to the _to address (with safety call)
   * @param from     Source addresses
   * @param to       Target addresses
   * @param tokenIds IDs of each token type
   * @param amounts  Transfer amounts per token type
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes memory
  ) external;

  /**
   * @notice Burn multiple types of tokens from the from
   * @param from     Source addresses
   * @param tokenIds IDs of each token type
   * @param amounts  Transfer amounts per token type
   */
  function burnBatch(
    address from,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts
  ) external;

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved) external;

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator)
    external
    view
    returns (bool isOperator);

  /**
   * @notice Get the balance of single account/token pair
   * @param account The address of the token holders
   * @param tokenId ID of the token
   * @return        The account's balance (0 or 1)
   */
  function balanceOf(address account, uint256 tokenId)
    external
    view
    returns (uint256);

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param accounts The addresses of the token holders
   * @param tokenIds ID of the Tokens
   * @return         The accounts's balances (0 or 1)
   */
  function balanceOfBatch(address[] memory accounts, uint256[] memory tokenIds)
    external
    view
    returns (uint256[] memory);
}

