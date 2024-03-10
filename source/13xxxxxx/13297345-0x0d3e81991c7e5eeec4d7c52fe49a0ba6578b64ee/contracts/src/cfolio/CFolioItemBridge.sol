/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '../../0xerc1155/tokens/ERC1155/ERC1155Holder.sol';
import '../../0xerc1155/utils/Address.sol';
import '../../0xerc1155/utils/Context.sol';

import '../token/interfaces/IWOWSCryptofolio.sol';
import '../token/interfaces/IWOWSERC1155.sol';
import '../token/interfaces/IERC1155BurnMintable.sol';
import '../utils/AddressBook.sol';
import '../utils/interfaces/IAddressRegistry.sol';
import '../utils/TokenIds.sol';

import './interfaces/ICFolioItemBridge.sol';
import './interfaces/ICFolioItemHandler.sol';

/**
 * @dev Minimalistic ERC1155 Holder for use only with WOWSCryptofolio
 *
 * This contract receives CFIs from the sftHolder contract for a
 * CFolio and performs all required Handle actions.
 */
contract CFolioItemBridge is ICFolioItemBridge, Context, ERC1155Holder {
  using TokenIds for uint256;
  using Address for address;

  //////////////////////////////////////////////////////////////////////////////
  // Routing
  //////////////////////////////////////////////////////////////////////////////

  // SFT contract
  IAddressRegistry private immutable _addressRegistry;

  // SFT contract
  IWOWSERC1155 private immutable _sftHolder;

  //////////////////////////////////////////////////////////////////////////////
  // Constants
  //////////////////////////////////////////////////////////////////////////////

  bytes4 internal constant ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  // Our balances
  mapping(uint256 => address) private _owners;

  // Operator Functions
  mapping(address => mapping(address => bool)) private _operators;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  event BridgeTransfer(
    address indexed _operator,
    address indexed _from,
    address indexed _to,
    uint256[] _ids,
    uint256[] _amounts
  );

  /**
   * @dev MUST emit when an approval is updated
   */
  event BridgeApproval(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Construct the contract
   *
   * @param addressRegistry Registry containing our system addresses
   *
   */
  constructor(IAddressRegistry addressRegistry) {
    _addressRegistry = addressRegistry;

    // The SFTHolder contract
    _sftHolder = IWOWSERC1155(
      addressRegistry.getRegistryEntry(AddressBook.SFT_HOLDER)
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of minimal IERC1155
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {ICFolioItemBridge-safeBatchTransferFrom}
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes memory
  ) external override {
    // Validate parameters
    require(
      (_msgSender() == from) || isApprovedForAll(from, _msgSender()),
      'CFIB: Not approved'
    );
    require(to != address(0), 'CFIB: Invalid recipient');
    require(tokenIds.length == amounts.length, 'CFIB: Length mismatch');

    // Transfer
    uint256 length = tokenIds.length;
    for (uint256 i = 0; i < length; ++i) {
      require(_owners[tokenIds[i]] == from, 'CFIB: Not owner');
      _owners[tokenIds[i]] = to;
    }
    _onTransfer(_msgSender(), from, to, tokenIds, amounts);
  }

  /**
   * @dev See {ICFolioItemBridge-burnBatch}
   */
  function burnBatch(
    address from,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts
  ) external override {
    // Validate parameters
    require(
      from == _msgSender() || isApprovedForAll(from, _msgSender()),
      'CFIB: Not approved'
    );
    require(tokenIds.length == amounts.length, 'CFIB: Length mismatch');

    // Transfer
    uint256 length = tokenIds.length;
    uint256 newLength = 0;
    for (uint256 i = 0; i < length; ++i) {
      if (amounts[i] > 0) {
        require(_owners[tokenIds[i]] == from, 'CFIB: Not owner');
        _owners[tokenIds[i]] = address(0);
        ++newLength;
      }
    }
    if (newLength < length) {
      uint256[] memory newTokenIds = new uint256[](newLength);
      uint256[] memory newAmounts = new uint256[](newLength);
      newLength = 0;
      for (uint256 i = 0; i < length; ++i) {
        if (amounts[i] > 0) {
          newTokenIds[newLength] = tokenIds[i];
          newAmounts[newLength++] = amounts[i];
        }
      }
      _onTransfer(_msgSender(), from, address(0), newTokenIds, newAmounts);
    } else {
      _onTransfer(_msgSender(), from, address(0), tokenIds, amounts);
    }
  }

  /**
   * @dev See {ICFolioItemBridge-setApprovalForAll}
   */
  function setApprovalForAll(address _operator, bool _approved)
    external
    override
  {
    // Update operator status
    _operators[_msgSender()][_operator] = _approved;
    emit BridgeApproval(_msgSender(), _operator, _approved);
  }

  /**
   * @dev See {ICFolioItemBridge-isApprovedForAll}
   */
  function isApprovedForAll(address _owner, address _operator)
    public
    view
    override
    returns (bool isOperator)
  {
    return _operators[_owner][_operator];
  }

  /**
   * @dev See {ICFolioItemBridge-balanceOf}
   */
  function balanceOf(address account, uint256 tokenId)
    external
    view
    override
    returns (uint256)
  {
    return _owners[tokenId] == account ? 1 : 0;
  }

  /**
   * @dev See {ICFolioItemBridge-balanceOfBatch}
   */
  function balanceOfBatch(address[] memory accounts, uint256[] memory tokenIds)
    external
    view
    override
    returns (uint256[] memory)
  {
    require(accounts.length == tokenIds.length, 'CFIB: Length mismatch');

    // Variables
    uint256[] memory batchBalances = new uint256[](accounts.length);

    // Iterate over each account and token ID
    for (uint256 i = 0; i < accounts.length; ++i) {
      batchBalances[i] = _owners[tokenIds[i]] == accounts[i] ? 1 : 0;
    }

    return batchBalances;
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
  ) public override returns (bytes4) {
    // Handle tokens
    uint256[] memory tokenIds = new uint256[](1);
    tokenIds[0] = tokenId;
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = amount;
    _onTokensReceived(operator, tokenIds, amounts, data);

    // Call ancestor
    return super.onERC1155Received(operator, from, tokenId, amount, data);
  }

  /**
   * @dev See {IERC1155TokenReceiver-onERC1155BatchReceived}
   */
  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes calldata data
  ) public override returns (bytes4) {
    // Handle tokens
    _onTokensReceived(operator, tokenIds, amounts, data);

    // Call ancestor
    return
      super.onERC1155BatchReceived(operator, from, tokenIds, amounts, data);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Internal details
  //////////////////////////////////////////////////////////////////////////////

  function _onTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory tokenIds,
    uint256[] memory amounts
  ) private {
    uint256 tokenId;
    // Verify that recipient is null or a cFolio
    if (to != address(0)) {
      tokenId = _sftHolder.addressToTokenId(to);
      require(
        tokenId != uint256(-1) && tokenId.isBaseCard(),
        'CFIB: Only baseCard'
      );
    }

    // Count SFT tokenIds
    uint256 length = tokenIds.length;
    uint256 numUniqueCFolioHandlers = 0;
    address[] memory uniqueCFolioHandlers = new address[](length);
    address[] memory cFolioHandlers = new address[](length);

    // Invoke callbacks / count SFTs
    for (uint256 i = 0; i < length; ++i) {
      tokenId = tokenIds[i];
      require(tokenId.isCFolioCard(), 'CFIB: Only cfolioItems');

      // CFolio SFTs always have one tradefloor / 1 CFolio dummy
      // which is needed to notify the CFolioHandler on SFT burn
      address cfolio = _sftHolder.tokenIdToAddress(tokenId.toSftTokenId());
      require(cfolio != address(0), 'CFIB: Invalid cfolio');

      address cFolioHandler = IWOWSCryptofolio(cfolio)._tradefloors(0);

      uint256 iter = numUniqueCFolioHandlers;
      while (iter > 0 && uniqueCFolioHandlers[iter - 1] != cFolioHandler)
        --iter;
      if (iter == 0) {
        require(cFolioHandler != address(0), 'Invalid CFH address');
        uniqueCFolioHandlers[numUniqueCFolioHandlers++] = cFolioHandler;
      }
      cFolioHandlers[i] = cFolioHandler;
    }

    // On Burn we need to transfer SFT ownership back
    // In case the call originates from cfolio itself, we burn the token
    if (to == address(0)) {
      if (from == operator) {
        // The call origins from Cryptofolio burn, don't transfer
        IERC1155BurnMintable(address(_sftHolder)).burnBatch(
          address(this),
          tokenIds,
          amounts
        );
      } else {
        IERC1155BurnMintable(address(_sftHolder)).safeBatchTransferFrom(
          address(this),
          from,
          tokenIds,
          amounts,
          ''
        );
      }
    } else if (to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(to).onERC1155BatchReceived(
        _msgSender(),
        from,
        tokenIds,
        amounts,
        ''
      );
      require(retval == ERC1155_BATCH_RECEIVED_VALUE, 'CFIB: CallOn failed');
    }

    // Handle CFolioItem transfers only if we are not migrating
    // Migration takes place if we are called from tradeFloor.
    // Remove the following condition if everything is migrated
    if (
      operator !=
      _addressRegistry.getRegistryEntry(AddressBook.TRADE_FLOOR_PROXY)
    )
      for (uint256 i = 0; i < numUniqueCFolioHandlers; ++i) {
        ICFolioItemHandler(uniqueCFolioHandlers[i]).onCFolioItemsTransferedFrom(
            from,
            to,
            tokenIds,
            cFolioHandlers
          );
      }

    emit BridgeTransfer(_msgSender(), from, to, tokenIds, amounts);
  }

  /**
   * @dev SFT token arrived, provide an NFT
   */
  function _onTokensReceived(
    address operator,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes memory data
  ) private {
    // We only support tokens from our SFT Holder contract
    require(_msgSender() == address(_sftHolder), 'CFIB: Invalid');

    // Validate parameters
    require(tokenIds.length == amounts.length, 'CFIB: Lengths mismatch');
    require(data.length == 20, 'CFIB: Destination invalid');

    address sftRecipient = _getAddress(data);
    require(sftRecipient != address(0), 'CFIB: Invalid data address');

    // Update state
    for (uint256 i = 0; i < tokenIds.length; ++i) {
      // Validate params
      require(amounts[i] == 1, 'CFIB: Amount invalid');
      uint256 tokenId = tokenIds[i];
      // Mint a token
      require(_owners[tokenId] == address(0), 'CFIB: already minted');
      _owners[tokenId] = sftRecipient;
    }
    _onTransfer(operator, address(0), sftRecipient, tokenIds, amounts);
  }

  /**
   * @dev Get the address from the user data parameter
   *
   * @param data Per ERC-1155, the data parameter is additional data with no
   * specified format, and is sent unaltered in the call to
   * {IERC1155Receiver-onERC1155Received} on the receiver of the minted token.
   */
  function _getAddress(bytes memory data) public pure returns (address addr) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      addr := mload(add(data, 20))
    }
  }
}

