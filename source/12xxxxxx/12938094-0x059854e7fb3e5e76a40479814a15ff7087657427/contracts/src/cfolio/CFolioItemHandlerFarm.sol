/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';

import '../../0xerc1155/interfaces/IERC1155.sol';
import '../../0xerc1155/interfaces/IERC1155TokenReceiver.sol';
import '../../0xerc1155/utils/SafeMath.sol';

import '../investment/interfaces/ICFolioFarm.sol'; // WOWS rewards
import '../token/interfaces/IWOWSERC1155.sol'; // SFT contract
import '../token/interfaces/IWOWSCryptofolio.sol';
import '../utils/AddressBook.sol';
import '../utils/interfaces/IAddressRegistry.sol';
import '../utils/TokenIds.sol';

import './interfaces/ICFolioItemBridge.sol';
import './interfaces/ICFolioItemHandler.sol';
import './interfaces/ISFTEvaluator.sol';

/**
 * @dev CFolioItemHandlerFarm manages CFolioItems, minted in the SFT contract.
 *
 * Minting CFolioItem SFTs is implemented in the WOWSSFTMinter contract, which
 * mints the SFT in the WowsERC1155 contract and calls setupCFolio in here.
 *
 * Normaly CFolioItem SFTs are locked in the main TradeFloor contract to allow
 * trading or transfer into a Base SFT card's c-folio.
 *
 * CFolioItem SFTs only earn rewards if they are inside the cfolio of a base
 * NFT. We get called from main TradeFloor every time an CFolioItem gets
 * transfered and calculate the new rewardable amount based on the reward %
 * of the base NFT.
 */
abstract contract CFolioItemHandlerFarm is ICFolioItemHandler, Context {
  using SafeMath for uint256;
  using TokenIds for uint256;

  //////////////////////////////////////////////////////////////////////////////
  // Routing
  //////////////////////////////////////////////////////////////////////////////

  // Route to SFT Minter. Only setup from SFT Minter allowed.
  address public sftMinter;

  // The TradeFloor contract which provides c-folio NFTs. This TradeFloor
  // contract calls the IMinterCallback interface functions.
  ICFolioItemBridge public immutable cfiBridge;

  // SFT evaluator
  ISFTEvaluator public immutable sftEvaluator;

  // Reward emitter
  ICFolioFarmOwnable public immutable cfolioFarm;

  // Admin
  address public immutable admin;

  // The SFT contract needed to check if the address is a c-folio
  IWOWSERC1155 public immutable sftHolder;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  /*
   * @dev Emitted when a reward is updated, either increased or decreased
   *
   * @param previousAmount The amount before updating the reward
   * @param newAmount The amount after updating the reward
   */
  event RewardUpdated(uint256 previousAmount, uint256 newAmount);

  /**
   * @dev Emitted when a new minter is set by the admin
   *
   * @param minter The new minter
   */
  event NewMinter(address minter);

  /**
   * @dev Emitted when the contract is destructed
   *
   * @param thisContract The address of this contract
   */
  event CFolioItemHandlerDestructed(address thisContract);

  //////////////////////////////////////////////////////////////////////////////
  // Modifiers
  //////////////////////////////////////////////////////////////////////////////

  modifier onlyBridge() {
    require(_msgSender() == address(cfiBridge), 'CFHI: Only CFIB');
    _;
  }

  modifier onlyAdmin() {
    require(_msgSender() == admin, 'CFIH: Only admin');
    _;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Constructs the CFolioItemHandlerFarm
   *
   * We gather all current addresses from address registry into immutable vars.
   * If one of the relevant addresses changes, the contract has to be updated.
   * There is little state here, user state is completely handled in CFolioFarm.
   */
  constructor(IAddressRegistry addressRegistry, bytes32 rewardFarmKey) {
    // TradeFloor
    cfiBridge = ICFolioItemBridge(
      addressRegistry.getRegistryEntry(AddressBook.CFOLIOITEM_BRIDGE_PROXY)
    );

    // Admin
    admin = addressRegistry.getRegistryEntry(AddressBook.MARKETING_WALLET);

    // The SFT holder
    sftHolder = IWOWSERC1155(
      addressRegistry.getRegistryEntry(AddressBook.SFT_HOLDER)
    );

    // The SFT minter
    sftMinter = addressRegistry.getRegistryEntry(AddressBook.SFT_MINTER);
    emit NewMinter(sftMinter);

    // SFT evaluator
    sftEvaluator = ISFTEvaluator(
      addressRegistry.getRegistryEntry(AddressBook.SFT_EVALUATOR_PROXY)
    );

    // WOWS rewards
    cfolioFarm = ICFolioFarmOwnable(
      addressRegistry.getRegistryEntry(rewardFarmKey)
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {ICFolioItemCallback} via {ICFolioItemHandler}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {ICFolioItemCallback-onCFolioItemsTransferedFrom}
   */
  function onCFolioItemsTransferedFrom(
    address from,
    address to,
    uint256[] calldata, /* tokenIds*/
    address[] calldata /* cfolioHandlers*/
  ) external override onlyBridge {
    // In case of transfer verify the target
    uint256 sftTokenId;

    if (
      to != address(0) &&
      (sftTokenId = sftHolder.addressToTokenId(to)) != uint256(-1)
    ) {
      _verifyTransferTarget(sftTokenId);
      _updateRewards(to, sftEvaluator.rewardRate(sftTokenId));
    }
    if (
      from != address(0) &&
      (sftTokenId = sftHolder.addressToTokenId(from)) != uint256(-1)
    ) {
      _updateRewards(from, sftEvaluator.rewardRate(sftTokenId));
    }
  }

  /**
   * @dev See {ICFolioItemCallback-appendHash}
   */
  function appendHash(address cfolioItem, bytes calldata current)
    external
    view
    override
    returns (bytes memory)
  {
    return
      abi.encodePacked(
        current,
        address(this),
        cfolioFarm.balanceOf(cfolioItem)
      );
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {ICFolioItemHandler}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {ICFolioItemHandler-sftUpgrade}
   */
  function sftUpgrade(uint256 tokenId, uint32 newRate) external override {
    // Validate access
    require(_msgSender() == address(sftEvaluator), 'CFIH: Invalid caller');
    require(tokenId.isBaseCard(), 'CFIH: Invalid token');

    // CFolio address
    address cfolio = sftHolder.tokenIdToAddress(tokenId);

    // Update state
    _updateRewards(cfolio, newRate);
  }

  /**
   * @dev See {ICFolioItemHandler-setupCFolio}
   *
   * Note: We place a dummy ERC1155 token with ID 0 into the CFolioItem's
   * c-folio. The reason is that we want to know if a c-folio item gets burned,
   * as burning an empty c-folio will result in no transfers. This prevents
   * tokens from becoming inaccessible.
   *
   * Refer to the Minimal ERC1155 section below to learn which functions are
   * needed for this.
   */
  function setupCFolio(
    address payer,
    uint256 sftTokenId,
    uint256[] calldata amounts
  ) external override {
    // Validate access
    require(_msgSender() == sftMinter, 'CFIH: Only sftMinter');

    // Validate parameters, no unmasking required, must be SFT
    address cFolio = sftHolder.tokenIdToAddress(sftTokenId);
    require(cFolio != address(0), 'CFIH: No cfolio');

    // Verify that this function is called the first time
    (, uint256 length) = IWOWSCryptofolio(cFolio).getCryptofolio(address(this));
    require(length == 0, 'CFIH: Not empty');

    // Transfer a dummy NFT token to cFolio so we get informed if the cFolio
    // gets burned
    IERC1155TokenReceiver(cFolio).onERC1155Received(
      address(this),
      address(0),
      0,
      1,
      ''
    );

    if (amounts.length > 0) {
      _deposit(cFolio, payer, amounts);
    }
  }

  /**
   * @dev See {ICFolioItemHandler-deposit}
   *
   * Note: tokenId can be owned by a base SFT
   * In this case base SFT cannot be locked
   *
   * There is only need to update rewards if tokenId
   * is part of an unlocked base SFT
   */
  function deposit(
    uint256 baseTokenId,
    uint256 tokenId,
    uint256[] calldata amounts
  ) external override {
    // Validate parameters
    (address baseCFolio, address itemCFolio) = _verifyAssetAccess(
      baseTokenId,
      tokenId
    );

    // Call the implementation
    _deposit(itemCFolio, _msgSender(), amounts);

    // Update rewards if CFI is inside cfolio
    if (baseCFolio != address(0))
      _updateRewards(baseCFolio, sftEvaluator.rewardRate(baseTokenId));
  }

  /**
   * @dev See {ICFolioItemHandler-withdraw}
   *
   * Note: tokenId can be owned by a base SFT. In this case, the base SFT
   * cannot be locked.
   *
   * There is only need to update rewards if tokenId is part of an unlocked
   * base SFT.
   */
  function withdraw(
    uint256 baseTokenId,
    uint256 tokenId,
    uint256[] calldata amounts
  ) external override {
    // Validate parameters
    (address baseCFolio, address itemCFolio) = _verifyAssetAccess(
      baseTokenId,
      tokenId
    );

    // Call the implementation
    _withdraw(itemCFolio, amounts);

    // Update rewards if CFI is inside cfolio
    if (baseCFolio != address(0))
      _updateRewards(baseCFolio, sftEvaluator.rewardRate(baseTokenId));
  }

  /**
   * @dev See {ICFolioItemHandler-getRewards}
   *
   * Note: tokenId must be a base SFT card
   *
   * We allow reward pull only for unlocked SFTs.
   */
  function getRewards(address recipient, uint256 tokenId) external override {
    // Validate parameters
    require(recipient != address(0), 'CFIH: Invalid recipient');
    require(tokenId.isBaseCard(), 'CFIH: Invalid tokenId');

    // Verify that tokenId has a valid cFolio address
    uint256 sftTokenId = tokenId.toSftTokenId();
    address cfolio = sftHolder.tokenIdToAddress(sftTokenId);
    require(cfolio != address(0), 'CFHI: No cfolio');

    // Verify that the tokenId is owned by msg.sender in case of direct
    // call or recipient in case of sftMinter call in the SFT contract.
    // This also verifies that the token is not locked in TradeFloor.
    require(
      IERC1155(address(sftHolder)).balanceOf(_msgSender(), sftTokenId) == 1 ||
        (_msgSender() == sftMinter &&
          IERC1155(address(sftHolder)).balanceOf(recipient, sftTokenId) == 1),
      'CFHI: Forbidden'
    );

    cfolioFarm.getReward(cfolio, recipient);
  }

  /**
   * @dev See {ICFolioItemHandler-getRewardInfo}
   */
  function getRewardInfo(uint256[] calldata tokenIds)
    external
    view
    override
    returns (bytes memory result)
  {
    uint256[5] memory uiData;

    // Get basic data once
    uiData = cfolioFarm.getUIData(address(0));

    // total / rewardDuration / rewardPerDuration
    result = abi.encodePacked(uiData[0], uiData[2], uiData[3]);

    uint256 length = tokenIds.length;
    if (length > 0) {
      // Iterate through all tokenIds and collect reward info
      for (uint256 i = 0; i < length; ++i) {
        uint256 sftTokenId = tokenIds[i].toSftTokenId();
        uint256 share = 0;
        uint256 earned = 0;
        if (sftTokenId.isBaseCard()) {
          address cfolio = sftHolder.tokenIdToAddress(sftTokenId);
          if (cfolio != address(0)) {
            uiData = cfolioFarm.getUIData(cfolio);
            share = uiData[1];
            earned = uiData[4];
          }
        }
        result = abi.encodePacked(result, share, earned);
      }
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // Internal interface
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Deposit amounts
   */
  function _deposit(
    address itemCFolio,
    address payer,
    uint256[] calldata amounts
  ) internal virtual;

  /**
   * @dev Withdraw amounts
   */
  function _withdraw(address itemCFolio, uint256[] calldata amounts)
    internal
    virtual;

  /**
   * @dev Verify if target base SFT is allowed
   */
  function _verifyTransferTarget(uint256 baseSftTokenId) internal virtual;

  //////////////////////////////////////////////////////////////////////////////
  // Maintanace
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Destruct implementation
   */
  function selfDestruct() external onlyAdmin {
    // Dispatch event
    CFolioItemHandlerDestructed(address(this));

    // Disable high-impact Slither detector "suicidal" here. Slither explains
    // that "CFolioItemHandlerFarm.selfDestruct() allows anyone to destruct the
    // contract", which is not the case due to the onlyAdmin modifier.
    //
    // slither-disable-next-line suicidal
    selfdestruct(payable(admin));
  }

  /**
   * @dev Set a new SFT minter
   */
  function setMinter(address newMinter) external onlyAdmin {
    // Validate parameters
    require(newMinter != address(0), 'CFIH: Invalid');

    // Update state
    sftMinter = newMinter;

    // Dispatch event
    emit NewMinter(newMinter);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Minimal ERC1155 implementation (called from SFTBase CFolio)
  //////////////////////////////////////////////////////////////////////////////

  // We do nothing for our dummy burn tokenId
  function setApprovalForAll(address, bool) external {}

  // Check for length == 1, and then return always 1
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
    external
    pure
    returns (uint256[] memory)
  {
    // Validate parameters
    require(_owners.length == 1 && _ids.length == 1, 'CFIH: Must be 1');

    uint256[] memory result = new uint256[](1);
    result[0] = 1;
    return result;
  }

  /**
   * @dev We don't allow burning non-empty c-folios
   */
  function burnBatch(
    address, /* account */
    uint256[] calldata tokenIds,
    uint256[] calldata
  ) external view {
    // Validate parameters
    require(tokenIds.length == 1, 'CFIH: Must be 1');

    // This call originates from the c-folio. We revert if there are investment
    // amounts left for this c-folio address.
    require(cfolioFarm.balanceOf(_msgSender()) == 0, 'CFIH: Not empty');
  }

  //////////////////////////////////////////////////////////////////////////////
  // Internal details
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Run through all cFolioItems collected in cFolio and select the amount
   * of tokens. Update cfolioFarm.
   */
  function _updateRewards(address cfolio, uint32 rate) private {
    // Get c-folio items of this base cFolio
    (uint256[] memory tokenIds, uint256 length) = IWOWSCryptofolio(cfolio)
      .getCryptofolio(address(cfiBridge));

    // Marginal increase in gas per item is around 25K. Bounding items to 100
    // fits in sensible gas limits.
    require(length <= 100, 'CFIH: Too many items');

    // Calculate new reward amount
    uint256 newRewardAmount = 0;
    for (uint256 i = 0; i < length; ++i) {
      address secondaryCFolio = sftHolder.tokenIdToAddress(tokenIds[i]);
      require(secondaryCFolio != address(0), 'CFIH: Invalid tokenId');
      if (IWOWSCryptofolio(secondaryCFolio)._tradefloors(0) == address(this))
        newRewardAmount = newRewardAmount.add(
          cfolioFarm.balanceOf(secondaryCFolio)
        );
    }
    newRewardAmount = newRewardAmount.mul(rate).div(1E6);

    // Calculate existing reward amount
    uint256 exitingRewardAmount = cfolioFarm.balanceOf(cfolio);

    // Compare amounts and add/remove shares
    if (newRewardAmount > exitingRewardAmount) {
      // Update state
      cfolioFarm.addShares(cfolio, newRewardAmount.sub(exitingRewardAmount));

      // Dispatch event
      emit RewardUpdated(exitingRewardAmount, newRewardAmount);
    } else if (newRewardAmount < exitingRewardAmount) {
      // Update state
      cfolioFarm.removeShares(cfolio, exitingRewardAmount.sub(newRewardAmount));

      // Dispatch event
      emit RewardUpdated(exitingRewardAmount, newRewardAmount);
    }
  }

  /**
   * @dev Verifies if an asset access operation is allowed
   *
   * @param baseTokenId Base card tokenId or uint(-1)
   * @param cfolioItemTokenId CFolioItem tokenId handled by this contract
   *
   * A tokenId is "unlocked" if msg.sender is the owner of a tokenId in SFT
   * contract. If baseTokenId is uint(-1), cfolioItemTokenId has to be be
   * unlocked, otherwise baseTokenId has to be unlocked and the locked
   * cfolioItemTokenId has to be inside its c-folio.
   */
  function _verifyAssetAccess(uint256 baseTokenId, uint256 cfolioItemTokenId)
    private
    view
    returns (address, address)
  {
    // Verify it's a cfolioItemTokenId
    require(cfolioItemTokenId.isCFolioCard(), 'CFHI: Not cFolioCard');

    // Verify that the tokenId is one of ours
    address cFolio = sftHolder.tokenIdToAddress(
      cfolioItemTokenId.toSftTokenId()
    );
    require(cFolio != address(0), 'CFIH: Invalid cFolioTokenId');
    require(
      IWOWSCryptofolio(cFolio)._tradefloors(0) == address(this),
      'CFIH: Not our SFT'
    );

    address baseCFolio = address(0);

    if (baseTokenId != uint256(-1)) {
      // Verify it's a c-folio base card
      require(baseTokenId.isBaseCard(), 'CFHI: Not baseCard');
      baseCFolio = sftHolder.tokenIdToAddress(baseTokenId.toSftTokenId());
      require(baseCFolio != address(0), 'CFIH: Invalid baseCFolioTokenId');

      // Verify that the tokenId is owned by msg.sender in SFT contract.
      // This also verifies that the token is not locked in TradeFloor.
      require(
        IERC1155(address(sftHolder)).balanceOf(_msgSender(), baseTokenId) == 1,
        'CFHI: Access denied (B)'
      );

      // Verify that the cfiTokenId is owned by given baseCFolio.
      // In V2 we have unlocked CFIs in baseCfolio in contrast to V1
      require(
        cfiBridge.balanceOf(baseCFolio, cfolioItemTokenId) == 1,
        'CFHI: Access denied (CF)'
      );
    } else {
      // Verify that the tokenId is owned by msg.sender in SFT contract.
      // This also verifies that the token is not locked in TradeFloor.
      require(
        IERC1155(address(sftHolder)).balanceOf(
          _msgSender(),
          cfolioItemTokenId
        ) == 1,
        'CFHI: Access denied'
      );
    }
    return (baseCFolio, cFolio);
  }
}

