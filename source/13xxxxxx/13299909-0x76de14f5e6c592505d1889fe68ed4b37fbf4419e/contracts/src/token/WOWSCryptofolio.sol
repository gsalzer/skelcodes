/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '../../0xerc1155/tokens/ERC1155/ERC1155Holder.sol';

import './interfaces/IWOWSCryptofolio.sol';

contract WOWSCryptofolio is IWOWSCryptofolio, ERC1155Holder {
  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  // The sftHolder contract
  address private immutable _sftContract;

  // The cfolioItemHandler
  address public override handler;

  //////////////////////////////////////////////////////////////////////////////
  // Modifier
  //////////////////////////////////////////////////////////////////////////////

  modifier onlyFromSftContract() {
    require(msg.sender == address(_sftContract), 'CF: Only sftContract');
    _;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  constructor(address sftContract) {
    _sftContract = sftContract;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {IWOWSCryptofolio}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IWOWSCryptofolio-setHandler}.
   */
  function setHandler(address newHandler)
    external
    override
    onlyFromSftContract
  {
    handler = newHandler;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {IERC1155TokenReceiver} via {ERC1155Holder}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IERC1155TokenReceiver-onERC1155Received}
   */
  function onERC1155Received(
    address operator,
    address from,
    uint256 tokenId,
    uint256 amount,
    bytes calldata data
  ) public override onlyFromSftContract returns (bytes4) {
    // Call ancestor
    return super.onERC1155Received(operator, from, tokenId, amount, data);
  }

  /**
   * @dev See {IERC1155TokenReceiver-onERC1155BatchReceived}
   */
  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    bytes calldata data
  ) public override onlyFromSftContract returns (bytes4) {
    // Call ancestor
    return
      super.onERC1155BatchReceived(operator, from, tokenIds, amounts, data);
  }
}

