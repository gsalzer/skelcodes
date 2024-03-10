/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Context.sol';

import '../cfolio/interfaces/ICFolioItemHandler.sol';
import '../cfolio/interfaces/ISFTEvaluator.sol';
import '../investment/interfaces/IRewardHandler.sol';
import '../token/interfaces/IERC1155BurnMintable.sol';
import '../token/interfaces/ITradeFloor.sol';
import '../token/interfaces/IWOWSCryptofolio.sol';
import '../token/interfaces/IWOWSERC1155.sol';
import '../utils/TokenIds.sol';

contract WOWSSftMinter is Context, Ownable {
  using TokenIds for uint256;
  using SafeERC20 for IERC20;

  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  // PricePerlevel, customLevel start at 0xFF
  mapping(uint16 => uint256) public _pricePerLevel;

  struct CFolioItemSft {
    ICFolioItemHandler handler;
    uint256 price;
    uint128 numMinted;
    uint128 maxMintable;
  }
  mapping(uint256 => CFolioItemSft) public cfolioItemSfts; // C-folio type to c-folio data
  ICFolioItemHandler[] private cfolioItemHandlers;

  uint256 public nextCFolioItemNft = (1 << 64);

  // The ERC1155 contract we are minting from
  IWOWSERC1155 private immutable _sftContract;

  // The cfolioItem wrapper bridge
  address private immutable _cfiBridge;

  // WOWS token contract
  IERC20 private immutable _wowsToken;

  // Reward handler which distributes WOWS
  IRewardHandler public rewardHandler;

  // TradeFloor Proxy contract
  address public tradeFloor;

  // SFTEvaluator to store the cfolioItemType
  ISFTEvaluator public sftEvaluator;

  // Set while minting CFolioToken
  bool private _setupCFolio;

  // 1.0 of the rewards go to distribution
  uint32 private constant ALL = 1 * 1e6;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  // Emitted if a new SFT is minted
  event Mint(
    address indexed recipient,
    uint256 tokenId,
    uint256 price,
    uint256 cfolioType
  );

  // Emitted if cFolio mint specifications (e.g. limits / price) have changed
  event CFolioSpecChanged(uint256[] ids, WOWSSftMinter upgradeFrom);

  // Emitted if the contract gets destroyed
  event Destruct();

  //////////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Contruct WOWSSftMinter
   *
   * @param owner Owner of this contract
   * @param wowsToken The WOWS ERC-20 token contract
   * @param rewardHandler_ Handler which distributes
   * @param sftContract Cryptofolio SFT source
   */
  constructor(
    address owner,
    IERC20 wowsToken,
    IRewardHandler rewardHandler_,
    IWOWSERC1155 sftContract,
    address cfiBridge
  ) {
    // Validate parameters
    require(owner != address(0), 'O: 0 address');
    require(address(wowsToken) != address(0), 'WT: 0 address');
    require(address(rewardHandler_) != address(0), 'RH: 0 address');
    require(address(sftContract) != address(0), 'SFT: 0 address');
    require(cfiBridge != address(0), 'CFIB: 0 address');

    // Initialize {Ownable}
    transferOwnership(owner);

    // Initialize state
    _sftContract = sftContract;
    _wowsToken = wowsToken;
    _cfiBridge = cfiBridge;
    rewardHandler = rewardHandler_;
  }

  //////////////////////////////////////////////////////////////////////////////
  // State modifiers
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Set prices for the given levels
   */
  function setPrices(uint16[] memory levels, uint256[] memory prices)
    external
    onlyOwner
  {
    // Validate parameters
    require(levels.length == prices.length, 'Length mismatch');

    // Update state
    for (uint256 i = 0; i < levels.length; ++i)
      _pricePerLevel[levels[i]] = prices[i];
  }

  /**
   * @dev Set new reward handler
   *
   * RewardHandler is by concept upgradeable / see investment::Controller.sol.
   */
  function setRewardHandler(IRewardHandler newRewardHandler)
    external
    onlyOwner
  {
    // Update state
    rewardHandler = newRewardHandler;
  }

  /**
   * @dev Set Trade Floor
   */
  function setTradeFloor(address tradeFloor_) external onlyOwner {
    // Validate parameters
    require(tradeFloor_ != address(0), 'Invalid TF');

    // Update state
    tradeFloor = tradeFloor_;
  }

  /**
   * @dev Set SFT evaluator
   */
  function setSFTEvaluator(ISFTEvaluator sftEvaluator_) external onlyOwner {
    // Validate parameters
    require(address(sftEvaluator_) != address(0), 'Invalid TF');

    // Update state
    sftEvaluator = sftEvaluator_;
  }

  /**
   * @dev Set the limitations, the price and the handlers for CFolioItem SFT's
   */
  function setCFolioSpec(
    uint256[] calldata cFolioTypes,
    address[] calldata handlers,
    uint128[] calldata maxMint,
    uint256[] calldata prices,
    WOWSSftMinter oldMinter
  ) external onlyOwner {
    // Validate parameters
    require(
      cFolioTypes.length == handlers.length &&
        handlers.length == maxMint.length &&
        maxMint.length == prices.length,
      'Length mismatch'
    );

    // Update state
    for (uint256 i = 0; i < cFolioTypes.length; ++i) {
      CFolioItemSft storage cfi = cfolioItemSfts[cFolioTypes[i]];
      cfi.handler = ICFolioItemHandler(handlers[i]);
      cfi.maxMintable = maxMint[i];
      cfi.price = prices[i];

      uint256 j = 0;
      for (; j < cfolioItemHandlers.length; ++j) {
        if (address(cfolioItemHandlers[j]) == handlers[i]) break;
      }
      if (j == cfolioItemHandlers.length) {
        cfolioItemHandlers.push(ICFolioItemHandler(handlers[i]));
      }
    }
    if (address(oldMinter) != address(0)) {
      for (uint256 i = 0; i < cFolioTypes.length; ++i) {
        (, , uint128 numMinted, ) = oldMinter.cfolioItemSfts(cFolioTypes[i]);
        cfolioItemSfts[cFolioTypes[i]].numMinted = numMinted;
      }
      nextCFolioItemNft = oldMinter.nextCFolioItemNft();
    }
    emit CFolioSpecChanged(cFolioTypes, oldMinter);
  }

  /**
   * @dev upgrades state from an existing WOWSSFTMinter
   */
  function destructContract() external onlyOwner {
    emit Destruct();

    // Disable high-impact Slither detector "suicidal" here. Slither explains
    // that "WOWSSftMinter.destructContract() allows anyone to destruct the
    // contract", which is not the case due to the {Ownable-onlyOwner} modifier.
    //
    // slither-disable-next-line suicidal
    selfdestruct(msg.sender);
  }

  /**
   * @dev Mint one of our stock card SFTs
   *
   * Approval of WOWS token required before the call.
   */
  function mintWowsSFT(
    address recipient,
    uint8 level,
    uint8 cardId
  ) external {
    // Validate parameters
    require(recipient != address(0), 'Invalid recipient');

    // Load state
    uint256 price = _pricePerLevel[level];

    // Validate state
    require(price > 0, 'No price available');

    // Get the next free mintable token for level / cardId
    (bool success, uint256 tokenId) = _sftContract.getNextMintableTokenId(
      level,
      cardId
    );
    require(success, 'Unsufficient cards');

    // Update state
    _mint(recipient, tokenId, price, 0);
  }

  /**
   * @dev Mint a custom token
   *
   * Approval of WOWS token required before the call.
   */
  function mintCustomSFT(
    address recipient,
    uint8 level,
    string memory uri
  ) external {
    // Validate parameters
    require(recipient != address(0), 'Invalid recipient');

    // Load state
    uint256 price = _pricePerLevel[0x100 + level];

    // Validate state
    require(price > 0, 'No price available');

    // Get the next free mintable token for level / cardId
    uint256 tokenId = _sftContract.getNextMintableCustomToken();

    // Custom baseToken only allowed < 64Bit
    require(tokenId.isBaseCard(), 'Max tokenId reached');

    // Set card level and uri
    _sftContract.setCustomCardLevel(tokenId, level);
    _sftContract.setCustomURI(tokenId, uri);

    // Update state
    _mint(recipient, tokenId, price, 0);
  }

  /**
   * @dev Mint a CFolioItem token
   *
   * Approval of WOWS token required before the call.
   *
   * Post-condition: `_setupCFolio` must be false.
   *
   * @param recipient Recipient of the SFT, unused if sftTokenId is != -1
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
  ) external {
    // Validate state
    require(!_setupCFolio, 'Already setting up');
    require(address(sftEvaluator) != address(0), 'SFTE not set');

    // Validate parameters
    require(recipient != address(0), 'Invalid recipient');

    // Load state
    CFolioItemSft storage sftData = cfolioItemSfts[cfolioItemType];

    // Validate state
    require(address(sftData.handler) != address(0), 'CFI Minter: Invalid type');
    require(sftData.numMinted < sftData.maxMintable, 'CFI Minter: sold out');

    address sftCFolio = address(0);
    if (sftTokenId != uint256(-1)) {
      require(sftTokenId.isBaseCard(), 'Invalid sftTokenId');

      // Get the CFolio contract address, it will be the final recipient
      sftCFolio = _sftContract.tokenIdToAddress(sftTokenId);
      require(sftCFolio != address(0), 'Bad sftTokenId');

      // Intermediate owner of the minted SFT
      recipient = address(this);

      // Allow this contract to be an ERC1155 holder
      _setupCFolio = true;
    }

    uint256 tokenId = nextCFolioItemNft++;
    require(tokenId.isCFolioCard(), 'Invalid cfolioItem tokenId');

    sftEvaluator.setCFolioItemType(tokenId, cfolioItemType);

    // Update state, mint SFT token
    sftData.numMinted += 1;
    _mint(recipient, tokenId, sftData.price, cfolioItemType);

    // Let CFolioHandler setup the new minted token
    sftData.handler.setupCFolio(_msgSender(), tokenId, investAmounts);

    // Check-effects-interaction not needed, as `_setupCFolio` can't be mutated
    // outside this function.

    // If the SFT's c-folio is final recipient of c-folio item, we call the
    // handler and lock the c-folio item in the TradeFloor contract before we transfer
    // it to the SFT
    if (sftCFolio != address(0)) {
      // Lock the SFT into the TradeFloor contract
      IERC1155BurnMintable(address(_sftContract)).safeTransferFrom(
        address(this),
        address(_cfiBridge),
        tokenId,
        1,
        abi.encodePacked(sftCFolio)
      );

      // Reset the temporary state which allows holding ERC1155 token
      _setupCFolio = false;
    }
  }

  /**
   * @dev Claim rewards from all c-folio farms
   *
   * @param sftTokenId valid SFT tokenId, must not be locked in TF
   */
  function claimSFTRewards(uint256 sftTokenId) external {
    for (uint256 i = 0; i < cfolioItemHandlers.length; ++i) {
      cfolioItemHandlers[i].getRewards(msg.sender, sftTokenId);
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // ERC1155Holder
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev We are a temorary token holder during CFolioToken mint step
   *
   * Only accept ERC1155 tokens during this setup.
   */
  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes memory
  ) external view returns (bytes4) {
    // Validate state
    require(_setupCFolio, 'Only during setup');

    // Call ancestor
    return this.onERC1155Received.selector;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Getters
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Query prices for given levels
   */
  function getPrices(uint16[] memory levels)
    external
    view
    returns (uint256[] memory)
  {
    uint256[] memory result = new uint256[](levels.length);
    for (uint256 i = 0; i < levels.length; ++i)
      result[i] = _pricePerLevel[levels[i]];
    return result;
  }

  /**
   * @dev retrieve mint information about cfolioItem
   */
  function getCFolioSpec(uint256[] calldata cFolioTypes)
    external
    view
    returns (
      uint256[] memory prices,
      uint128[] memory numMinted,
      uint128[] memory maxMintable
    )
  {
    uint256 length = cFolioTypes.length;
    prices = new uint256[](length);
    numMinted = new uint128[](length);
    maxMintable = new uint128[](length);

    for (uint256 i; i < length; ++i) {
      CFolioItemSft storage cfi = cfolioItemSfts[cFolioTypes[i]];
      prices[i] = cfi.price;
      numMinted[i] = cfi.numMinted;
      maxMintable[i] = cfi.maxMintable;
    }
  }

  /**
   * @dev Get all tokenIds from SFT and TF contract owned by account.
   */
  function getTokenIds(address account)
    external
    view
    returns (uint256[] memory sftTokenIds, uint256[] memory tfTokenIds)
  {
    require(account != address(0), 'Null address');
    sftTokenIds = _sftContract.getTokenIds(account);
    tfTokenIds = ITradeFloor(tradeFloor).getTokenIds(account);
  }

  /**
   * @dev Get underlying information (cFolioItems / value) for given tokenIds.
   *
   * @param tokenIds the tokenIds information should be queried
   * @return result [%,MintTime,NumItems,[tokenId,type,numAssetValues,[assetValue]]]...
   */
  function getTokenInformation(uint256[] calldata tokenIds)
    external
    view
    returns (bytes memory result)
  {
    uint256[] memory cFolioItems;
    uint256[] memory oneCFolioItem = new uint256[](1);
    uint256 cfolioLength;
    uint256 rewardRate;
    uint256 timestamp;

    for (uint256 i = 0; i < tokenIds.length; ++i) {
      if (tokenIds[i].isBaseCard()) {
        // Only main TradeFloor supported
        uint256 sftTokenId = tokenIds[i].toSftTokenId();
        address cfolio = _sftContract.tokenIdToAddress(sftTokenId);
        if (address(cfolio) != address(0)) {
          (cFolioItems, cfolioLength) = IWOWSCryptofolio(cfolio).getCryptofolio(
            _cfiBridge
          );
        } else {
          cFolioItems = oneCFolioItem;
          cfolioLength = 0;
        }

        rewardRate = sftEvaluator.rewardRate(tokenIds[i]);
        (timestamp, ) = _sftContract.getTokenData(sftTokenId);
      } else {
        oneCFolioItem[0] = tokenIds[i];
        cfolioLength = 1;
        cFolioItems = oneCFolioItem; // Reference, no copy
        rewardRate = 0;
        timestamp = 0;
      }

      result = abi.encodePacked(result, rewardRate, timestamp, cfolioLength);

      for (uint256 j = 0; j < cfolioLength; ++j) {
        uint256 sftTokenId = cFolioItems[j].toSftTokenId();
        uint256 cfolioType = sftEvaluator.getCFolioItemType(sftTokenId);
        uint256[] memory amounts;

        address cfolio = _sftContract.tokenIdToAddress(sftTokenId);
        if (address(cfolio) != address(0)) {
          address handler = IWOWSCryptofolio(cfolio)._tradefloors(0);
          if (handler != address(0))
            amounts = ICFolioItemHandler(handler).getAmounts(cfolio);
        }

        result = abi.encodePacked(
          result,
          cFolioItems[j],
          cfolioType,
          amounts.length,
          amounts
        );
      }
    }
  }

  /**
   * @dev Get balances of given ERC20 addresses.
   */
  function getErc20Balances(address account, address[] calldata erc20)
    external
    view
    returns (uint256[] memory amounts)
  {
    amounts = new uint256[](erc20.length);
    for (uint256 i = 0; i < erc20.length; ++i)
      amounts[i] = erc20[i] == address(0)
        ? 0
        : IERC20(erc20[i]).balanceOf(account);
  }

  /**
   * @dev Get allowances of given ERC20 addresses.
   */
  function getErc20Allowances(
    address account,
    address[] calldata spender,
    address[] calldata erc20
  ) external view returns (uint256[] memory amounts) {
    // Validate parameters
    require(spender.length == erc20.length, 'Length mismatch');

    amounts = new uint256[](spender.length);
    for (uint256 i = 0; i < spender.length; ++i)
      amounts[i] = erc20[i] == address(0)
        ? 0
        : IERC20(erc20[i]).allowance(account, spender[i]);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Internal functionality
  //////////////////////////////////////////////////////////////////////////////

  function _mint(
    address recipient,
    uint256 tokenId,
    uint256 price,
    uint256 cfolioType
  ) internal {
    // Transfer WOWS from user to reward handler
    if (price > 0)
      _wowsToken.safeTransferFrom(_msgSender(), address(rewardHandler), price);

    // Mint the token
    IERC1155BurnMintable(address(_sftContract)).mint(recipient, tokenId, 1, '');

    // Distribute the rewards
    if (price > 0) rewardHandler.distribute2(recipient, price, ALL);

    // Log event
    emit Mint(recipient, tokenId, price, cfolioType);
  }
}

