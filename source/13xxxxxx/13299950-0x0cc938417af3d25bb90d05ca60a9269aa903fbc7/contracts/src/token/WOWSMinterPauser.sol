/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0 AND MIT
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '../../0xerc1155/access/AccessControl.sol';
import '../../0xerc1155/tokens/ERC1155/ERC1155Metadata.sol';
import '../../0xerc1155/tokens/ERC1155/ERC1155MintBurn.sol';

/**
 * @dev Partial implementation of https://eips.ethereum.org/EIPS/eip-1155[ERC1155]
 * Multi Token Standard
 */
contract WOWSMinterPauser is
  Context,
  AccessControl,
  ERC1155MintBurn,
  ERC1155Metadata
{
  //////////////////////////////////////////////////////////////////////////////
  // Roles
  //////////////////////////////////////////////////////////////////////////////

  // Role to mint new tokens
  bytes32 public constant MINTER_ROLE = 'MINTER_ROLE';

  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  // Pause
  bool private _pauseActive;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  // Event triggered when _pause state changed
  event Pause(bool active);

  //////////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////////

  constructor() {}

  //////////////////////////////////////////////////////////////////////////////
  // Pausing interface
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Pauses all token transfers.
   *
   * Requirements:
   *
   * - The caller must have the `DEFAULT_ADMIN_ROLE`.
   */
  function pause(bool active) public {
    // Validate access
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Only admin');

    if (_pauseActive != active) {
      // Update state
      _pauseActive = active;
      emit Pause(active);
    }
  }

  /**
   * @dev Returns true if the contract is paused, and false otherwise.
   */
  function paused() public view returns (bool) {
    return _pauseActive;
  }

  function _pause(bool active) internal {
    _pauseActive = active;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Minting interface
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Creates `amount` new tokens for `to`, of token type `tokenId`.
   *
   * See {ERC1155-_mint}.
   *
   * Requirements:
   *
   * - The caller must have the `MINTER_ROLE`.
   */
  function mint(
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  ) public virtual {
    // Validate access
    require(hasRole(MINTER_ROLE, _msgSender()), 'Only minter');

    // Validate parameters
    require(to != address(0), "Can't mint to zero address");

    // Update state
    _mint(to, tokenId, amount, data);
  }

  /**
   * @dev Batched variant of {mint}.
   */
  function mintBatch(
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    bytes calldata data
  ) public virtual {
    // Validate access
    require(hasRole(MINTER_ROLE, _msgSender()), 'Only minter');

    // Validate parameters
    require(to != address(0), "Can't mint to zero address");
    require(tokenIds.length == amounts.length, "Lengths don't match");

    // Update state
    _batchMint(to, tokenIds, amounts, data);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Burning interface
  //////////////////////////////////////////////////////////////////////////////

  function burn(
    address account,
    uint256 id,
    uint256 value
  ) public virtual {
    // Validate access
    require(
      account == _msgSender() || isApprovedForAll(account, _msgSender()),
      'Caller is not owner nor approved'
    );

    // Update state
    _burn(account, id, value);
  }

  function burnBatch(
    address account,
    uint256[] calldata ids,
    uint256[] calldata values
  ) public virtual {
    // Validate access
    require(
      account == _msgSender() || isApprovedForAll(account, _msgSender()),
      'Caller is not owner nor approved'
    );

    // Update state
    _batchBurn(account, ids, values);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {ERC1155}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {ERC1155-_beforeTokenTransfer}.
   *
   * This function is necessary due to diamond inheritance.
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  ) internal virtual override {
    // Validate state
    require(!_pauseActive, 'Transfer operation paused!');

    // Call ancestor
    super._beforeTokenTransfer(operator, from, to, tokenId, amount, data);
  }

  /**
   * @dev See {ERC1155-_beforeBatchTokenTransfer}.
   *
   * This function is necessary due to diamond inheritance.
   */
  function _beforeBatchTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override {
    // Valiate state
    require(!_pauseActive, 'Transfer operation paused!');

    // Call ancestor
    super._beforeBatchTokenTransfer(
      operator,
      from,
      to,
      tokenIds,
      amounts,
      data
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {ERC165}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {ERC165-supportsInterface}
   */
  function supportsInterface(bytes4 _interfaceID)
    public
    pure
    virtual
    override(ERC1155, ERC1155Metadata)
    returns (bool)
  {
    return super.supportsInterface(_interfaceID);
  }
}

