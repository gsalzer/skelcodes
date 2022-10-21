/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '../../0xerc1155/interfaces/IERC20.sol';
import '../../0xerc1155/tokens/ERC1155/ERC1155Holder.sol';

import '../token/interfaces/IWOWSCryptofolio.sol';
import '../token/interfaces/IWOWSERC1155.sol';
import '../utils/AddressBook.sol';
import '../utils/interfaces/IAddressRegistry.sol';
import '../utils/TokenIds.sol';

import './interfaces/ICFolioItemCallback.sol';
import './WOWSMinterPauser.sol';

abstract contract OpenSeaProxyRegistry {
  mapping(address => address) public proxies;
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-1155[ERC1155]
 * Multi Token Standard, including the Metadata URI extension.
 *
 * This contract is an extension of the minter preset. It accepts the address
 * of the contract minting the token via the ERC-1155 data parameter. When
 * the token is transferred or burned, the minter is notified.
 *
 * Token ID allocation:
 *
 *   - 32Bit Stock Cards
 *   - 32Bit Custom Cards
 *   - Remaining CFolio NFTs
 */
contract TradeFloor is WOWSMinterPauser, ERC1155Holder {
  using TokenIds for uint256;

  //////////////////////////////////////////////////////////////////////////////
  // Roles
  //////////////////////////////////////////////////////////////////////////////

  // Only OPERATORS can approve when trading is restricted
  bytes32 public constant OPERATOR_ROLE = 'OPERATOR_ROLE';

  //////////////////////////////////////////////////////////////////////////////
  // Constants
  //////////////////////////////////////////////////////////////////////////////

  // solhint-disable-next-line const-name-snakecase
  string public constant name = 'Wolves of Wall Street - C-Folio NFTs';
  // solhint-disable-next-line const-name-snakecase
  string public constant symbol = 'WOWSCFNFT';

  //////////////////////////////////////////////////////////////////////////////
  // Modifier
  //////////////////////////////////////////////////////////////////////////////

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Only admin');
    _;
  }

  modifier notNull(address adr) {
    require(adr != address(0), 'Null address');
    _;
  }

  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Per token information, used to cap NFT's and to allow querying a list
   * of NFT's owned by an address
   */
  struct ListKey {
    uint256 index;
  }

  // Per token information
  struct TokenInfo {
    bool minted; // Make sure we only mint 1
    ListKey listKey; // Next tokenId in the owner linkedList
  }
  // slither-disable-next-line uninitialized-state
  mapping(uint256 => TokenInfo) private _tokenInfos;

  // Mapping owner -> first owned token
  //
  // Note that we work 1 based here because of initialization
  // e.g. firstId == 1 links to tokenId 0;
  struct Owned {
    uint256 count;
    ListKey listKey; // First tokenId in linked list
  }
  // slither-disable-next-line uninitialized-state
  mapping(address => Owned) private _owned;

  // Our SFT contract, needed to check for locked transfers
  IWOWSERC1155 private immutable _sftHolder;
  // Migration!! This is the old sft contract
  IWOWSERC1155 private immutable _sftHolderOld;

  // Restrict approvals to OPERATOR_ROLE members
  bool private _tradingRestricted = false;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Emitted when the state of restriction has updated
   *
   * @param tradingRestricted True if trading has been restricted, false otherwise
   */
  event RestrictionUpdated(bool tradingRestricted);

  //////////////////////////////////////////////////////////////////////////////
  // OpenSea compatibility
  //////////////////////////////////////////////////////////////////////////////

  // OpenSea per-account proxy registry. Used to whitelist Approvals and save
  // GAS.
  OpenSeaProxyRegistry private immutable _openSeaProxyRegistry;
  address private immutable _deployer;

  // OpenSea events
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  //////////////////////////////////////////////////////////////////////////////
  // Rarible compatibility
  //////////////////////////////////////////////////////////////////////////////

  /*
   * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
   * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
   *
   * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
   */
  bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

  uint256 private _fee;
  address private _feeRecipient;

  // Rarible events
  // solhint-disable-next-line event-name-camelcase
  event CreateERC1155_v1(address indexed creator, string name, string symbol);
  event SecondarySaleFees(
    uint256 tokenId,
    address payable[] recipients,
    uint256[] bps
  );

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Construct the contract
   *
   * @param addressRegistry Registry containing our system addresses
   *
   * Note: Pause operation in this context. Only calls from Proxy allowed.
   */
  constructor(
    IAddressRegistry addressRegistry,
    OpenSeaProxyRegistry openSeaProxyRegistry,
    IWOWSERC1155 sftHolderOld
  ) {
    // Initialize {AccessControl}
    _setupRole(
      DEFAULT_ADMIN_ROLE,
      _getAddressRegistryAddress(addressRegistry, AddressBook.ADMIN_ACCOUNT)
    );

    // Immutable, visible for all contexts
    _sftHolder = IWOWSERC1155(
      _getAddressRegistryAddress(addressRegistry, AddressBook.SFT_HOLDER_PROXY)
    );

    _sftHolderOld = sftHolderOld;

    // Immutable, visible for all contexts
    _openSeaProxyRegistry = openSeaProxyRegistry;

    // Immutable, visible for all contexts
    _deployer = _getAddressRegistryAddress(
      addressRegistry,
      AddressBook.DEPLOYER
    );

    // Pause this instance
    _pause(true);
  }

  /**
   * @dev One time contract initializer
   *
   * @param tokenUriPrefix The ERC-1155 metadata URI Prefix
   * @param contractUri The contract metadata URI
   */
  function initialize(
    IAddressRegistry addressRegistry,
    string memory tokenUriPrefix,
    string memory contractUri
  ) public {
    // Validate state
    require(_feeRecipient == address(0), 'already initialized');

    // Initialize {AccessControl}
    address admin = _getAddressRegistryAddress(
      addressRegistry,
      AddressBook.ADMIN_ACCOUNT
    );
    _setupRole(DEFAULT_ADMIN_ROLE, admin);

    // Initialize {ERC1155Metadata}
    _setBaseMetadataURI(tokenUriPrefix);
    _setContractMetadataURI(contractUri);

    _feeRecipient = _getAddressRegistryAddress(
      addressRegistry,
      AddressBook.REWARD_HANDLER
    );
    _fee = 1000; // 10%

    // This event initializes Rarible storefront
    emit CreateERC1155_v1(_deployer, name, symbol);

    // OpenSea enable storefront editing
    emit OwnershipTransferred(address(0), _deployer);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Getters
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Return list of tokenIds owned by `account`
   */
  function getTokenIds(address account)
    external
    view
    returns (uint256[] memory)
  {
    Owned storage list = _owned[account];
    uint256[] memory result = new uint256[](list.count);
    ListKey storage key = list.listKey;
    for (uint256 i = 0; i < list.count; ++i) {
      result[i] = key.index;
      key = _tokenInfos[key.index].listKey;
    }
    return result;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {IERC1155} via {WOWSMinterPauser}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IERC1155-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes calldata data
  ) public override notNull(from) notNull(to) {
    // Call parent
    super.safeTransferFrom(from, to, tokenId, amount, data);

    uint256[] memory tokenIds = new uint256[](1);
    uint256[] memory amounts = new uint256[](1);
    tokenIds[0] = tokenId;
    amounts[0] = amount;

    _onTransfer(from, to, tokenIds, amounts);
  }

  /**
   * @dev See {IERC1155-safeBatchTransferFrom}.
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    bytes calldata data
  ) public override notNull(from) notNull(to) {
    // Validate parameters
    require(tokenIds.length == amounts.length, "Lengths don't match");

    // Call parent
    super.safeBatchTransferFrom(from, to, tokenIds, amounts, data);

    _onTransfer(from, to, tokenIds, amounts);
  }

  /**
   * @dev See {IERC1155-setApprovalForAll}.
   *
   * Override setApprovalForAll to be able to restrict to known operators.
   */
  function setApprovalForAll(address operator, bool approved)
    public
    virtual
    override
  {
    // Validate access
    require(
      !_tradingRestricted || hasRole(OPERATOR_ROLE, operator),
      'forbidden'
    );

    // Call ancestor
    super.setApprovalForAll(operator, approved);
  }

  /**
   * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
   */
  function isApprovedForAll(address account, address operator)
    public
    view
    override
    returns (bool)
  {
    if (!_tradingRestricted && address(_openSeaProxyRegistry) != address(0)) {
      // Whitelist OpenSea proxy contract for easy trading.
      OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(
        _openSeaProxyRegistry
      );
      if (proxyRegistry.proxies(account) == operator) {
        return true;
      }
    }

    // Call ancestor
    return super.isApprovedForAll(account, operator);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {IERC1155MetadataURI} via {WOWSMinterPauser}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IERC1155MetadataURI-uri}.
   *
   * Revert for unminted SFT NFTs.
   */
  function uri(uint256 tokenId) public view override returns (string memory) {
    // Validate state
    require(_tokenInfos[tokenId].minted, 'Not minted');
    // Load state
    return _uri('', tokenId, 0);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {WOWSMinterPauser}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {ERC1155MintBurn-_burn}.
   */
  function burn(
    address account,
    uint256 tokenId,
    uint256 amount
  ) public override notNull(account) {
    // Call ancestor
    super.burn(account, tokenId, amount);

    // Perform internal handling
    uint256[] memory tokenIds = new uint256[](1);
    uint256[] memory amounts = new uint256[](1);
    tokenIds[0] = tokenId;
    amounts[0] = amount;
    _onTransfer(account, address(0), tokenIds, amounts);
  }

  /**
   * @dev See {ERC1155MintBurn-_batchBurn}.
   */
  function burnBatch(
    address account,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts
  ) public virtual override notNull(account) {
    // Validate parameters
    require(tokenIds.length == amounts.length, "Lengths don't match");

    // Call ancestor
    super.burnBatch(account, tokenIds, amounts);

    // Perform internal handling
    _onTransfer(account, address(0), tokenIds, amounts);
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
    _onTokensReceived(from, tokenIds, amounts, data);

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
    _onTokensReceived(from, tokenIds, amounts, data);

    // Call ancestor
    return
      super.onERC1155BatchReceived(operator, from, tokenIds, amounts, data);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Administrative functions
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {ERC1155Metadata-setBaseMetadataURI}.
   */
  function setBaseMetadataURI(string memory baseMetadataURI)
    external
    onlyAdmin
  {
    // Set state
    _setBaseMetadataURI(baseMetadataURI);
  }

  /**
   * @dev Set contract metadata URI
   */
  function setContractMetadataURI(string memory newContractUri)
    public
    onlyAdmin
  {
    _setContractMetadataURI(newContractUri);
  }

  /**
   * @dev Register interfaces
   */
  function supportsInterface(bytes4 _interfaceID)
    public
    pure
    virtual
    override(WOWSMinterPauser, ERC1155Holder)
    returns (bool)
  {
    // Register rarible fee interface
    if (_interfaceID == _INTERFACE_ID_FEES) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }

  /**
   * @dev Withdraw tokenAddress ERC20token to destination
   *
   * A future improvement would be to swap the token into WOWS.
   *
   * @param tokenAddress the address of the token to transfer. Cannot be
   * rewardToken.
   */
  function collectGarbage(address tokenAddress) external onlyAdmin {
    // Transfer token to msg.sender
    uint256 amountToken = IERC20(tokenAddress).balanceOf(address(this));
    if (amountToken > 0)
      IERC20(tokenAddress).transfer(_msgSender(), amountToken);
  }

  /**
   * @dev Restrict trading to OPERATOR_ROLE (see setApprovalForAll)
   */
  function restrictTrading(bool restrict) external onlyAdmin {
    // Update state
    _tradingRestricted = restrict;

    // Dispatch event
    emit RestrictionUpdated(restrict);
  }

  /**
   * @dev Self destruct implementation contract
   */
  function destructContract(address payable newContract) external onlyAdmin {
    // slither-disable-next-line suicidal
    selfdestruct(newContract);
  }

  //////////////////////////////////////////////////////////////////////////////
  // OpenSea compatibility
  //////////////////////////////////////////////////////////////////////////////

  function isOwner() external view returns (bool) {
    return _msgSender() == owner();
  }

  function owner() public view returns (address) {
    return _deployer;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Rarible fees and events
  //////////////////////////////////////////////////////////////////////////////

  function setFee(uint256 fee) external onlyAdmin {
    // Update state
    _fee = fee;
  }

  function setFeeRecipient(address feeRecipient) external onlyAdmin {
    // Update state
    _feeRecipient = feeRecipient;
  }

  function getFeeRecipients(uint256)
    public
    view
    returns (address payable[] memory)
  {
    // Return value
    address payable[] memory recipients = new address payable[](1);

    // Load state
    recipients[0] = payable(_feeRecipient);
    return recipients;
  }

  function getFeeBps(uint256) public view returns (uint256[] memory) {
    // Return value
    uint256[] memory bps = new uint256[](1);

    // Load state
    bps[0] = _fee;

    return bps;
  }

  function logURI(uint256 tokenId) external {
    emit URI(uri(tokenId), tokenId);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Internal details
  //////////////////////////////////////////////////////////////////////////////

  function _onTransfer(
    address from,
    address to,
    uint256[] memory tokenIds,
    uint256[] memory amounts
  ) private {
    // Count SFT tokenIds
    uint256 length = tokenIds.length;
    uint256 validLength = 0;
    // Relink owner
    for (uint256 i = 0; i < length; ++i) {
      if (amounts[i] == 1) {
        _relinkOwner(from, to, tokenIds[i], uint256(-1));
        ++validLength;
      }
      // CryptoFolios send 0 amount!!
      else require(amounts[i] == 0, 'TF: Invalid amount');
    }

    // On Burn we need to transfer SFT ownership back
    if (validLength > 0 && to == address(0)) {
      uint256[] memory sftTokenIds = new uint256[](validLength);
      uint256[] memory sftAmounts = new uint256[](validLength);
      validLength = 0;
      for (uint256 i = 0; i < length; ++i) {
        if (amounts[i] == 1) {
          uint256 tokenId = tokenIds[i];
          sftTokenIds[validLength] = tokenId.toSftTokenId();
          sftAmounts[validLength++] = 1;
        }
      }

      IWOWSERC1155 sftHolder = _sftHolder;
      // Migration!!! Remove if all TF's are on new contract
      if (
        address(_sftHolderOld) != address(0) &&
        _sftHolderOld.balanceOf(address(this), sftTokenIds[0]) == 1
      ) sftHolder = _sftHolderOld;

      sftHolder.safeBatchTransferFrom(
        address(this),
        _msgSender(),
        sftTokenIds,
        sftAmounts,
        ''
      );
    }
  }

  /**
   * @dev SFT token arrived, provide an NFT
   */
  function _onTokensReceived(
    address from,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes memory data
  ) private {
    // We only support tokens from our SFT Holder contract
    require(_msgSender() == address(_sftHolder), 'TF: Invalid sender');

    // Validate parameters
    require(tokenIds.length == amounts.length, 'TF: Lengths mismatch');

    // To save gas we allow minting directly into a given recipient
    address sftRecipient;
    if (data.length == 20) {
      sftRecipient = _getAddress(data);
      require(sftRecipient != address(0), 'TF: invalid recipient');
    } else sftRecipient = from;

    // Update state
    uint256[] memory mintedTokenIds = new uint256[](tokenIds.length);
    for (uint256 i = 0; i < tokenIds.length; ++i) {
      require(amounts[i] == 1, 'Amount != 1 not allowed');

      uint256 mintedTokenId = _hashedTokenId(tokenIds[i]);
      mintedTokenIds[i] = mintedTokenId;

      // OpenSea only listens to TransferSingle event on mint
      _mintAndEmit(sftRecipient, mintedTokenId);
    }
    _onTransfer(address(0), sftRecipient, mintedTokenIds, amounts);
  }

  /**
   * @dev Ownership change -> update linked list owner -> tokenId
   *
   * If tokenIdNew is != uint256(-1) this function executes an
   * ownership transfer of "from" from tokenId to tokenIdNew
   * In this case "to" must be set to 0.
   */
  function _relinkOwner(
    address from,
    address to,
    uint256 tokenId,
    uint256 tokenIdNew
  ) internal {
    // Load state
    TokenInfo storage tokenInfo = _tokenInfos[tokenId];

    // Remove tokenId from List
    if (from != address(0)) {
      // Load state
      Owned storage fromList = _owned[from];

      // Validate state
      require(fromList.count > 0, 'Count mismatch');

      ListKey storage key = fromList.listKey;
      uint256 count = fromList.count;

      // Search the token which links to tokenId
      for (; count > 0 && key.index != tokenId; --count)
        key = _tokenInfos[key.index].listKey;
      require(key.index == tokenId, 'Key mismatch');

      if (tokenIdNew == uint256(-1)) {
        // Unlink prev -> tokenId
        key.index = tokenInfo.listKey.index;
        // Decrement count
        fromList.count--;
      } else {
        // replace tokenId -> tokenIdNew
        key.index = tokenIdNew;
        TokenInfo storage tokenInfoNew = _tokenInfos[tokenIdNew];
        require(!tokenInfoNew.minted, 'Must not be minted');
        tokenInfoNew.listKey.index = tokenInfo.listKey.index;
        tokenInfoNew.minted = true;
      }
      // Unlink tokenId -> next
      tokenInfo.listKey.index = 0;
      require(tokenInfo.minted, 'Must be minted');
      tokenInfo.minted = false;
    }

    // Update state
    if (to != address(0)) {
      Owned storage toList = _owned[to];
      tokenInfo.listKey.index = toList.listKey.index;
      require(!tokenInfo.minted, 'Must not be minted');
      tokenInfo.minted = true;
      toList.listKey.index = tokenId;
      toList.count++;
    }
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

  /**
   * @dev Save contract size by wrappng external call into an internal
   */
  function _getAddressRegistryAddress(IAddressRegistry reg, bytes32 data)
    private
    view
    returns (address)
  {
    return reg.getRegistryEntry(data);
  }

  /**
   * @dev Save contract size by wrappng external call into an internal
   */
  function _addressToTokenId(address tokenAddress)
    private
    view
    returns (uint256)
  {
    return _sftHolder.addressToTokenId(tokenAddress);
  }

  /**
   * @dev internal mint + event emiting
   */
  function _mintAndEmit(address recipient, uint256 tokenId) private {
    _mint(recipient, tokenId, 1, '');

    // Rarible needs to be informed about fees
    emit SecondarySaleFees(tokenId, getFeeRecipients(0), getFeeBps(0));
  }

  /**
   * @dev Calculate a 128-bit hash for making tokenIds unique to underlying asset
   *
   * @param sftTokenId The tokenId from SFT contract from that we use the first 128 bit
   * TokenIds in SFT contract are limited to max 128 Bit in WowsSftMinter contract.
   */
  function _hashedTokenId(uint256 sftTokenId) private view returns (uint256) {
    bytes memory hashData;
    uint256[] memory tokenIds;
    uint256 tokenIdsLength;
    if (sftTokenId.isBaseCard()) {
      // It's a base card, calculate hash using all cfolioItems
      address cfolio = _sftHolder.tokenIdToAddress(sftTokenId);
      require(cfolio != address(0), 'TF: src token invalid');
      tokenIds = _sftHolder.getTokenIds(cfolio);
      tokenIdsLength = tokenIds.length;
      hashData = abi.encodePacked(address(this), sftTokenId);
    } else {
      // It's a cfolioItem itself, only calculate underlying value
      tokenIds = new uint256[](1);
      tokenIds[0] = sftTokenId;
      tokenIdsLength = 1;
    }

    // Run through all cfolioItems and let their single CFolioItemHandler
    // append hashable data
    for (uint256 i = 0; i < tokenIdsLength; ++i) {
      address cfolio = _sftHolder.tokenIdToAddress(tokenIds[i].toSftTokenId());
      require(cfolio != address(0), 'TF: item token invalid');

      address handler = IWOWSCryptofolio(cfolio).handler();
      require(handler != address(0), 'TF: item handler invalid');

      hashData = ICFolioItemCallback(handler).appendHash(cfolio, hashData);
    }

    uint256 hashNum = uint256(keccak256(hashData));
    return (hashNum ^ (hashNum << 128)).maskHash() | sftTokenId;
  }
}

