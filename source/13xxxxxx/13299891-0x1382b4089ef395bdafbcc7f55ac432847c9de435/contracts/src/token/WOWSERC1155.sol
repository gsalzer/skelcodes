/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '../../0xerc1155/access/AccessControl.sol';
import '../../0xerc1155/interfaces/IERC1155TokenReceiver.sol';
import '../../0xerc1155/utils/Address.sol';

import './interfaces/IWOWSCryptofolio.sol';
import './interfaces/IWOWSERC1155.sol';
import '../cfolio/interfaces/ICFolioItemHandler.sol';
import '../utils/Clones.sol';
import '../utils/TokenIds.sol';

contract WOWSERC1155 is IWOWSERC1155, AccessControl {
  using TokenIds for uint256;
  using Address for address;

  //////////////////////////////////////////////////////////////////////////////
  // Constants
  //////////////////////////////////////////////////////////////////////////////

  // Role to mint new tokens
  bytes32 public constant MINTER_ROLE = 'MINTER_ROLE';

  // Role which is allowed to call chain related functions
  bytes32 public constant CHAIN_ROLE = 'CHAIN_ROLE';

  // Token receiver return value
  bytes4 internal constant ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  // Pause all transfer operations
  bool public pause;

  // Card state of custom NFT's
  mapping(uint256 => uint8) private _customLevels;

  struct ListKey {
    uint256 index;
  }

  // Per-token data
  struct TokenInfo {
    address owner; // Make sure we only mint 1
    uint64 timestamp;
    ListKey listKey; // Next tokenId in the owner linkedList
  }
  mapping(uint256 => TokenInfo) private _tokenInfos;

  struct ExternalNft {
    address collection;
    uint256 tokenId;
  }
  mapping(uint256 => ExternalNft) public externalNfts;

  // Mapping tokenId -> generated address
  mapping(uint256 => address) private _tokenIdToAddress;

  // Mapping generated address -> tokenId
  mapping(address => uint256) private _addressToTokenId;

  // Mapping owner -> first owned token
  //
  // Note that we work 1-based here because of initialization
  // e.g. firstId == 1 links to tokenId 0
  struct Owned {
    uint256 count;
    ListKey listKey; // First tokenId in linked list
  }
  mapping(address => Owned) private _owned;

  // cfolioType of cfolioItem
  mapping(uint256 => uint256) private _cfolioItemTypes;

  // Our master cryptofolio used for clones
  address public cryptofolio;

  //////////////////////////////////////////////////////////////////////////////
  // Modifier
  //////////////////////////////////////////////////////////////////////////////

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'SFT: Only admin');
    _;
  }

  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, _msgSender()), 'SFT: Only minter');
    _;
  }

  modifier onlyChain() {
    require(hasRole(CHAIN_ROLE, _msgSender()), 'SFT: Only chain operator');
    _;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  // Fired on each transfer operation
  event SftTokenTransfer(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256[] tokenIds
  );

  // Fired if the type of a CFolioItem is set
  event UpdatedCFolioType(uint256 indexed tokenId, uint256 cfolioItemType);

  // Fired if a Cryptofolio clone was set
  event CryptofolioSet(address cryptofolio);

  // Fired if a SidechainTunnel was set
  event SidechainTunnelSet(address sidechainTunnel);

  // Fired if we selfdestruct contract
  event Destruct();

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  /*
   * @dev URI is for WOWS predefined NFT's
   *
   * The other token URI's must be set separately.
   */
  constructor(address owner) {
    // Initialize {AccessControl}
    _setupRole(DEFAULT_ADMIN_ROLE, owner);
  }

  function initialize(address owner) public {
    // Check for one time initialization
    require(
      getRoleMemberCount(DEFAULT_ADMIN_ROLE) == 0,
      'SFT: Already initialized'
    );

    // Initialize {AccessControl}
    _setupRole(DEFAULT_ADMIN_ROLE, owner);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {IWOWSERC1155}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * See {IWOWSERC1155-mintBatch}.
   */
  function mintBatch(
    address to,
    uint256[] calldata tokenIds,
    bytes calldata data
  ) external override onlyMinter {
    // Validate parameters
    require(to != address(0), 'SFT: Zero address');

    _tokenTransfer(address(0), to, tokenIds, data);
  }

  /**
   * See {IWOWSERC1155-burnBatch}.
   */
  function burnBatch(address account, uint256[] calldata tokenIds)
    external
    override
  {
    // Validate access
    require(account == _msgSender(), 'SFT: Caller not owner');

    _tokenTransfer(account, address(0), tokenIds, '');
  }

  /**
   * See {IWOWSERC1155-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes calldata data
  ) external override {
    require(from != address(0) && to != address(0), 'SFT: Null address');
    require(amount == 1, 'SFT: Wrong amount');

    _tokenTransfer(from, to, _toArray(tokenId), data);
  }

  /**
   * See {IWOWSERC1155-safeBatchTransferFrom}.
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    bytes calldata data
  ) external override {
    require(from != address(0) && to != address(0), 'SFT: Null address');
    require(
      amounts.length == 0 || tokenIds.length == amounts.length,
      'SFT: Length mismatch'
    );
    if (amounts.length > 0) {
      for (uint256 i = 0; i < amounts.length; ++i)
        require(amounts[i] == 1, 'SFT: Wrong amount');
    }

    _tokenTransfer(from, to, tokenIds, data);
  }

  /**
   * @dev See {IWOWSERC1155-addressToTokenId}.
   */
  function addressToTokenId(address tokenAddress)
    public
    view
    override
    returns (uint256)
  {
    // Load state
    uint256 tokenId = _addressToTokenId[tokenAddress];

    // Error case: token ID isn't known
    if (_tokenIdToAddress[tokenId] != tokenAddress) {
      return uint256(-1);
    }

    // Success
    return tokenId;
  }

  /**
   * @dev See {IWOWSERC1155-tokenIdToAddress}.
   */
  function tokenIdToAddress(uint256 tokenId)
    external
    view
    override
    returns (address)
  {
    // Load state
    return _tokenIdToAddress[tokenId];
  }

  /**
   * @dev See {IWOWSERC1155-setCustomCardLevel}.
   */
  function setCustomCardLevel(uint256 tokenId, uint8 cardLevel)
    public
    override
    onlyMinter
  {
    // Validate parameter
    require(!tokenId.isCustomCard(), 'SFT: Only custom cards');

    // Update state
    _customLevels[tokenId] = cardLevel;
  }

  /**
   * @dev See {IWOWSERC1155-setCFolioType}.
   */
  function setCFolioItemType(uint256 tokenId, uint256 cfolioItemType)
    external
    override
    onlyMinter
  {
    require(tokenId.isCFolioCard(), 'SFT: Invalid tokenId');

    _cfolioItemTypes[tokenId] = cfolioItemType;

    // Dispatch event
    emit UpdatedCFolioType(tokenId, cfolioItemType);
  }

  /**
   * @dev See {IWOWSERC1155-setExternalNft}.
   */
  function setExternalNft(
    uint256 tokenId,
    address externalCollection,
    uint256 externalTokenId
  ) external override onlyMinter {
    ExternalNft storage nft = externalNfts[tokenId];

    nft.collection = externalCollection;
    nft.tokenId = externalTokenId;
  }

  /**
   * @dev See {IWOWSERC1155-deleteExternalNft}.
   */
  function deleteExternalNft(uint256 tokenId) external override onlyMinter {
    delete (externalNfts[tokenId]);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Getters
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IWOWSERC1155-getTokenData}.
   */
  function getTokenData(uint256 tokenId)
    external
    view
    override
    returns (uint64 mintTimestamp, uint8 level)
  {
    // Decode token ID
    uint8 _level = _getLevel(tokenId);

    // Load state
    return (_tokenInfos[tokenId].timestamp, _level);
  }

  /**
   * @dev See {IWOWSERC1155-getTokenIds}.
   */
  function getTokenIds(address account)
    public
    view
    override
    returns (uint256[] memory)
  {
    // Load state
    Owned storage list = _owned[account];

    // Return value
    uint256[] memory result = new uint256[](list.count);

    // Search state
    ListKey storage key = list.listKey;
    for (uint256 i = 0; i < list.count; ++i) {
      result[i] = key.index;
      key = _tokenInfos[key.index].listKey;
    }

    return result;
  }

  /**
   * @dev See {IWOWSERC1155-getCFolioItemType}.
   */
  function getCFolioItemType(uint256 tokenId)
    external
    view
    override
    returns (uint256)
  {
    // Validate parameters
    require(tokenId.isCFolioCard(), 'SFT: Invalid tokenId');

    // Load state
    return _cfolioItemTypes[tokenId.toSftTokenId()];
  }

  /**
   * @dev See {IWOWSERC1155-balanceOf}.
   */
  function balanceOf(address owner, uint256 tokenId)
    external
    view
    override
    returns (uint256)
  {
    return _tokenInfos[tokenId].owner == owner ? 1 : 0;
  }

  /**
   * @dev See {IWOWSERC1155-balanceOfBatch}.
   */
  function balanceOfBatch(
    address[] calldata owners,
    uint256[] calldata tokenIds
  ) external view override returns (uint256[] memory) {
    require(owners.length == tokenIds.length, 'SFT: Length mismatch');
    uint256[] memory result = new uint256[](owners.length);

    for (uint256 i = 0; i < owners.length; ++i)
      result[i] = _tokenInfos[tokenIds[i]].owner == owners[i] ? 1 : 0;

    return result;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Maintanance
  //////////////////////////////////////////////////////////////////////////////

  // Pause all transfer operations
  function setPause(bool _pause) external onlyAdmin {
    pause = _pause;
  }

  // Set Cryptofolio clone
  function setCryptofolio(address newCryptofolio) external onlyAdmin {
    cryptofolio = newCryptofolio;
    emit CryptofolioSet(cryptofolio);
  }

  /**
   * @dev destruct old implementation
   */
  function destructContract() external onlyAdmin {
    emit Destruct();

    // Disable high-impact Slither detector "suicidal" here. Slither explains
    // that "WOWSSftMinter.destructContract() allows anyone to destruct the
    // contract", which is not the case due to the {Ownable-onlyOwner} modifier.
    //
    // slither-disable-next-line suicidal
    selfdestruct(_msgSender());
  }

  //////////////////////////////////////////////////////////////////////////////
  // Internal functionality
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Handles transfer of an SFT token
   */
  function _tokenTransfer(
    address from,
    address to,
    uint256[] memory tokenIds,
    bytes memory data
  ) private {
    require(!pause, 'SFT: Paused!');

    uint256 numUniqueCFolioHandlers = 0;
    address[] memory uniqueCFolioHandlers = new address[](tokenIds.length);
    address[] memory cFolioHandlers = new address[](tokenIds.length);
    uint256 toTokenId = to == address(0) ? uint256(-1) : addressToTokenId(to);

    for (uint256 i = 0; i < tokenIds.length; ++i) {
      uint256 tokenId = tokenIds[i];

      // Load state
      address tokenAddress = _tokenIdToAddress[tokenId];
      TokenInfo storage tokenInfo = _tokenInfos[tokenId];

      // Minting
      if (from == address(0)) {
        // Validate state
        require(tokenInfo.owner == address(0), 'SFT: Already minted');

        // solhint-disable-next-line not-rely-on-time
        tokenInfo.timestamp = uint64(block.timestamp);

        // Create a new WOWSCryptofolio by cloning masterTokenReceiver
        // The clone itself is a minimal delegate proxy.
        if (tokenAddress == address(0)) {
          tokenAddress = Clones.clone(cryptofolio);
          _tokenIdToAddress[tokenId] = tokenAddress;
          if (tokenId.isCFolioCard()) {
            require(data.length == 20, 'SFT: Invalid data');
            address handler = _getAddress(data);
            require(handler != address(0), 'SFT: Invalid address');
            IWOWSCryptofolio(tokenAddress).setHandler(handler);
          } else if (data.length > i * 32) {
            //Migration / Bridge. First uint is recipient
            tokenInfo.timestamp = uint64(_getUint256(data, i));
          }
        }
        _addressToTokenId[tokenAddress] = tokenId;
      }
      // Burning
      else {
        if (to == address(0)) {
          // Make sure underlying assets gets burned
          if (tokenId.isBaseCard()) {
            uint256[] memory cfolioItems = getTokenIds(tokenAddress);
            if (cfolioItems.length > 0) {
              _tokenTransfer(tokenAddress, to, cfolioItems, data);
            }
          }
        }
        // Allow transfer only if from is either owner or owner of cfolio.
        require(
          tokenInfo.owner == from || _cfolioOwner(tokenInfo.owner) == from,
          'SFT: Access denied'
        );
      }
      // Update state
      tokenInfo.owner = to;

      if (!tokenId.isBaseCard()) {
        address handler = IWOWSCryptofolio(tokenAddress).handler();
        uint256 iter = numUniqueCFolioHandlers;
        while (iter > 0 && uniqueCFolioHandlers[iter - 1] != handler) --iter;
        if (iter == 0) {
          require(handler != address(0), 'SFT: Invalid handler');
          uniqueCFolioHandlers[numUniqueCFolioHandlers++] = handler;
        }
        cFolioHandlers[i] = handler;
      } else {
        // Avoid cfolio as child of cfolio
        require(toTokenId == uint256(-1), 'SFT: Invalid to');
      }

      // Remove tokenId from List
      if (from != address(0)) {
        // Load state
        Owned storage fromList = _owned[from];

        // Validate state
        require(fromList.count > 0, 'SFT: Count mismatch');

        ListKey storage key = fromList.listKey;
        uint256 count = fromList.count;

        // Search the token which links to tokenId
        for (; count > 0 && key.index != tokenId; --count)
          key = _tokenInfos[key.index].listKey;
        require(key.index == tokenId, 'SFT: Key mismatch');

        // Unlink prev -> tokenId
        key.index = tokenInfo.listKey.index;
        // Unlink tokenId -> next
        tokenInfo.listKey.index = 0;
        // Decrement count
        fromList.count--;
      }

      // Update state
      if (to != address(0)) {
        Owned storage toList = _owned[to];
        tokenInfo.listKey.index = toList.listKey.index;
        toList.listKey.index = tokenId;
        toList.count++;
      }
    }

    // Notify to that NFT's has arrived
    if (to.isContract()) {
      uint256[] memory amounts = new uint256[](tokenIds.length);
      for (uint256 i = 0; i < tokenIds.length; ++i) amounts[i] = 1;
      bytes4 retval = IERC1155TokenReceiver(to).onERC1155BatchReceived(
        msg.sender,
        from,
        tokenIds,
        amounts,
        data
      );
      require(retval == ERC1155_BATCH_RECEIVED_VALUE, 'SFTE: Unsupported');
    }

    for (uint256 i = 0; i < numUniqueCFolioHandlers; ++i) {
      ICFolioItemHandler(uniqueCFolioHandlers[i]).onCFolioItemsTransferedFrom(
        from,
        to,
        tokenIds,
        cFolioHandlers
      );
    }
    emit SftTokenTransfer(_msgSender(), from, to, tokenIds);
  }

  /**
   * @dev Get the level of a given token
   *
   * @param tokenId The ID of the token
   *
   * @return level The level of the token
   */
  function _getLevel(uint256 tokenId) private view returns (uint8 level) {
    if (tokenId.isCustomCard()) {
      level = _customLevels[tokenId];
    } else {
      level = uint8(tokenId >> 24);
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
   * @dev Get the uint256 from the user data parameter
   */
  function _getUint256(bytes memory data, uint256 index)
    private
    pure
    returns (uint256 val)
  {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      val := mload(add(data, mul(0x20, add(index, 1))))
    }
  }

  /**
   * @dev Convert uint to uint[](1)
   */
  function _toArray(uint256 value)
    private
    pure
    returns (uint256[] memory result)
  {
    result = new uint256[](1);
    result[0] = value;
  }

  /**
   * @dev Return owner of cfolio
   */
  function _cfolioOwner(address cfolio) private view returns (address) {
    uint256 tokenId = addressToTokenId(cfolio);
    if (tokenId == uint256(-1)) return address(0);
    return _tokenInfos[tokenId].owner;
  }
}

