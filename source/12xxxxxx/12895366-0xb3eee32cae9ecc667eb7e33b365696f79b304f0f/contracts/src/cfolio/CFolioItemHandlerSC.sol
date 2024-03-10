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
import '../../0xerc1155/interfaces/IERC20.sol';
import '../../0xerc1155/utils/SafeERC20.sol';
import '../../0xerc1155/utils/SafeMath.sol';
import '../../interfaces/curve/CurveDepositInterface.sol';

import '../investment/interfaces/ICFolioFarm.sol'; // Wolves rewards
import '../token/interfaces/IWOWSCryptofolio.sol';
import '../token/interfaces/IWOWSERC1155.sol'; // SFT contract
import '../utils/interfaces/IAddressRegistry.sol';
import '../utils/AddressBook.sol';
import '../utils/TokenIds.sol';

import './interfaces/ICFolioItemHandler.sol';
import './interfaces/ISFTEvaluator.sol';

/**
 * @dev CFolioItemHandlerSC manages CFolioItems, minted in the SFT contract.
 *
 * Minting CFolioItem SFTs is implemented in the WOWSSFTMinter contract, which
 * mints the SFT in the WowsERC1155 contract and calls setupCFolio in here.
 *
 * Normaly CFolioItem SFTs are locked in the main TradeFloor contract to allow
 * trading or transfer into a Base SFT card's c-folio.
 *
 * CFolioItem SFTs only earn rewards if they are inside the cfolio of a base
 * NFT. We get called from main TradeFloor every time an CFolioItem gets
 * transfered and calculate the new rewardable ?? amount based on the reward %
 * of the base NFT.
 */
contract CFolioItemHandlerSC is ICFolioItemHandler, Context {
  using SafeMath for uint256;
  using TokenIds for uint256;
  using SafeERC20 for IERC20;

  //////////////////////////////////////////////////////////////////////////////
  // Routing
  //////////////////////////////////////////////////////////////////////////////

  // Route to SFT Minter. Only setup from SFT Minter allowed.
  address public sftMinter;

  // The TradeFloor contract which provides c-folio NFTs. This TradeFloor
  // contract calls the IMinterCallback interface functions.
  address public immutable tradeFloor;

  // SFT evaluator
  ISFTEvaluator public immutable sftEvaluator;

  // Reward emitter
  ICFolioFarmOwnable public immutable cfolioFarm;

  // Admin
  address public immutable admin;

  // The SFT contract needed to check if the address is a c-folio
  IWOWSERC1155 private immutable sftHolder;

  // Address registry containing system addresses
  IAddressRegistry private immutable _addressRegistry;

  // Curve Y pool token contract
  IERC20 public immutable curveYToken;

  // Curve Y pool deposit contract
  ICurveFiDepositY public immutable curveYDeposit;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  /*
   * @dev Emitted when a reward is updated, either increased or decreased
   *
   * @param previousAmount The amount before updating the reward
   * @param newAmount The amount after updating the reward
   */
  event SCRewardUpdated(uint256 previousAmount, uint256 newAmount);

  /**
   * @dev Emitted when a new minter is set by the admin
   *
   * @param minter The new minter
   */
  event NewSCMinter(address minter);

  /**
   * @dev Emitted when the contract is upgraded
   *
   * @param thisContract The address of this contract
   * @param newContract The address of the contract being upgraded to
   */
  event SCContractUpgraded(address thisContract, address newContract);

  //////////////////////////////////////////////////////////////////////////////
  // Modifiers
  //////////////////////////////////////////////////////////////////////////////

  modifier onlyTradeFloor {
    require(_msgSender() == address(tradeFloor), 'TFCLP: only TF');
    _;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Constructs the CFolioItemHandlerSC
   *
   * We gather all current addresses from address registry into immutable vars.
   * If one of the relevant addresses changes, the contract has to be updated.
   * There is little state here, user state is completely handled in CFolioFarm.
   */
  constructor(IAddressRegistry addressRegistry) {
    // Address registry
    _addressRegistry = addressRegistry;

    // TradeFloor
    tradeFloor = addressRegistry.getRegistryEntry(
      AddressBook.TRADE_FLOOR_PROXY
    );

    // Admin
    admin = addressRegistry.getRegistryEntry(AddressBook.MARKETING_WALLET);

    // The SFT holder
    sftHolder = IWOWSERC1155(
      addressRegistry.getRegistryEntry(AddressBook.SFT_HOLDER)
    );

    // The SFT minter
    sftMinter = addressRegistry.getRegistryEntry(AddressBook.SFT_MINTER);
    emit NewSCMinter(sftMinter);

    // SFT evaluator
    sftEvaluator = ISFTEvaluator(
      addressRegistry.getRegistryEntry(AddressBook.SFT_EVALUATOR_PROXY)
    );

    // The Y pool deposit contract
    curveYDeposit = ICurveFiDepositY(
      addressRegistry.getRegistryEntry(AddressBook.CURVE_Y_DEPOSIT)
    );

    // The Y pool token contract
    curveYToken = IERC20(
      addressRegistry.getRegistryEntry(AddressBook.CURVE_Y_TOKEN)
    );

    // WOWS reward farm
    cfolioFarm = ICFolioFarmOwnable(
      addressRegistry.getRegistryEntry(AddressBook.BOIS_REWARDS)
    );
  }

  /**
   * @dev One time contract initializer
   */
  function initialize() public {
    // Approve stablecoin spending
    for (uint256 i = 0; i < 4; ++i) {
      address underlyingCoin = curveYDeposit.underlying_coins(int128(i));
      IERC20(underlyingCoin).safeApprove(address(curveYDeposit), uint256(-1));
    }

    // Approve yCRV spending
    curveYToken.approve(address(curveYDeposit), uint256(-1));
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
  ) external override onlyTradeFloor {
    // In case of transfer verify the target
    uint256 sftTokenId;

    if (
      to != address(0) &&
      (sftTokenId = sftHolder.addressToTokenId(to)) != uint256(-1)
    ) {
      (, uint8 level) = sftHolder.getTokenData(sftTokenId);
      require((LEVEL2BOIS & (uint256(1) << level)) > 0, 'CFIH: Bois only');
      _updateRewards(to, sftEvaluator.rewardRate(sftTokenId));
    }

    if (
      from != address(0) &&
      (sftTokenId = sftHolder.addressToTokenId(from)) != uint256(-1)
    ) _updateRewards(from, sftEvaluator.rewardRate(sftTokenId));
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

  /**
   * @dev See {ICFolioItemCallback-uri}
   */
  function uri(
    uint256 /* tokenId */
  ) external pure override returns (string memory) {
    return '';
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
   * as burning an empty c-folio will result in no transfers. This prevents LP
   * tokens from becoming inaccessible.
   *
   * Refer to the Minimal ERC1155 section below to learn which functions are
   * needed for this.
   *
   * @param sftTokenId The token ID of the SFT being setup
   * @param amounts The token amounts, in this order: DAI, USDC, USDT, TUSD, yCRV
   * `amounts` can be empty when setting up a CFolio with no initial investments.
   */
  function setupCFolio(
    address payer,
    uint256 sftTokenId,
    uint256[] calldata amounts
  ) external override {
    // Validate access
    require(_msgSender() == sftMinter, 'Only SFTMinter');

    // Validate parameters, no unmasking required, must be SFT
    address cFolio = sftHolder.tokenIdToAddress(sftTokenId);
    require(cFolio != address(0), 'Invalid sftTokenId');
    require(
      amounts.length == 0 || amounts.length == 5,
      'Need DAI/USDC/USDT/TUSD/yCRV'
    );

    // Verify that this function is called the first time
    try IWOWSCryptofolio(cFolio)._tradefloors(0) returns (address) {
      revert('CFIH: TradeFloor not empty');
    } catch {}

    // Keep track of how many Y pool tokens were received
    uint256 beforeBalance = curveYToken.balanceOf(address(this));

    // Handle stablecoins
    if (amounts.length > 0) {
      uint256[4] memory stableAmounts;
      uint256 totalStableAmount;
      for (uint256 i = 0; i < 4; ++i) {
        address underlyingCoin = curveYDeposit.underlying_coins(int128(i));

        IERC20(underlyingCoin).safeTransferFrom(
          payer,
          address(this),
          amounts[i]
        );

        uint256 stableAmount = IERC20(underlyingCoin).balanceOf(address(this));

        stableAmounts[i] = stableAmount;
        totalStableAmount += stableAmount;
      }

      if (totalStableAmount > 0) {
        // Call to external contract
        curveYDeposit.add_liquidity(stableAmounts, 0);

        // Validate state
        uint256 afterStableBalance = curveYToken.balanceOf(address(this));
        require(
          afterStableBalance > beforeBalance,
          'No liquidity from stables'
        );
      }

      // Handle Y pool
      uint256 yPoolAmount = amounts[4];

      if (yPoolAmount > 0) {
        curveYToken.transferFrom(payer, address(this), yPoolAmount);
      }

      // Validate state
      uint256 afterBalance = curveYToken.balanceOf(address(this));

      // Record assets in Farm contract. They don't earn rewards.
      // addAsset must only be called from Investment CFolios
      // This call is allowed without any investment.
      if (afterBalance > beforeBalance)
        cfolioFarm.addAssets(cFolio, afterBalance.sub(beforeBalance));
    }

    // Transfer a dummy NFT token to cFolio so we get informed if the cFolio
    // gets burned
    IERC1155TokenReceiver(cFolio).onERC1155Received(
      address(this),
      address(0),
      0,
      1,
      ''
    );
  }

  /**
   * @dev See {ICFolioItemHandler-deposit}
   *
   * Note: tokenId can be owned by a base SFT. In this case base SFT cannot be
   *     locked.
   *
   * There is only need to update rewards if tokenId is part of an unlocked
   * base SFT.
   */
  function deposit(
    uint256 baseTokenId,
    uint256 tokenId,
    uint256[] calldata amounts
  ) external override {
    // Validate parameters
    require(amounts.length == 5, 'Need DAI/USDC/USDT/TUSD/yCRV');
    (address baseCFolio, address itemCFolio) =
      _verifyAssetAccess(baseTokenId, tokenId);

    // Keep track of how many Y pool tokens were received
    uint256 beforeBalance = curveYToken.balanceOf(address(this));

    // Handle stablecoins
    uint256[4] memory stableAmounts;
    uint256 totalStableAmount;
    for (uint256 i = 0; i < 4; ++i) {
      address underlyingCoin = curveYDeposit.underlying_coins(int128(i));

      IERC20(underlyingCoin).safeTransferFrom(
        _msgSender(),
        address(this),
        amounts[i]
      );

      uint256 stableAmount = IERC20(underlyingCoin).balanceOf(address(this));

      stableAmounts[i] = stableAmount;
      totalStableAmount += stableAmount;
    }

    if (totalStableAmount > 0) {
      // Call to external contract
      curveYDeposit.add_liquidity(stableAmounts, 0);

      // Validate state
      uint256 afterStableBalance = curveYToken.balanceOf(address(this));
      require(afterStableBalance > beforeBalance, 'No liquidity from stables');
    }

    // Handle Y pool
    uint256 yPoolAmount = amounts[4];

    if (yPoolAmount > 0) {
      curveYToken.transferFrom(_msgSender(), address(this), yPoolAmount);
    }

    // Validate state
    uint256 afterBalance = curveYToken.balanceOf(address(this));
    require(afterBalance > beforeBalance, 'No liquidity added');

    // Record assets in Farm contract. They don't earn rewards.
    // addAsset must only be called from Investment CFolios
    cfolioFarm.addAssets(itemCFolio, afterBalance.sub(beforeBalance));

    if (baseTokenId != uint256(-1)) {
      _updateRewards(baseCFolio, sftEvaluator.rewardRate(baseTokenId));
    }
  }

  /**
   * @dev See {ICFolioItemHandler-withdraw}
   *
   * Note: tokenId can be owned by a base SFT. In this case, the base SFT
   * cannot be locked.
   *
   * There is only need to update rewards if tokenId is part of an unlocked
   * base SFT.
   *
   * @param baseTokenId The token ID of the base c-folio, or uint(-1) if
   *     tokenId is not owned by a base c-folio.
   * @param tokenId The token ID of the investment SFT to withdraw from
   * @param amounts The amounts, with the tokens being DAI/USDC/USDT/TUSD/yCRV.
   *     yCRV must be specified, as yCRV tokens are held by this contract.
   *     If all four stablecoin amounts are 0, then yCRV is withdrawn to the
   *     sender's wallet. If exactly one of the four stablecoin amounts is > 0,
   *     then yCRV will be converted to the specified stablecoin. The amount in
   *     the array is the minimum amount of stablecoin tokens that must be
   *     withdrawn.
   */
  function withdraw(
    uint256 baseTokenId,
    uint256 tokenId,
    uint256[] calldata amounts
  ) external override {
    // Validate parameters
    require(amounts.length == 5, 'Need DAI/USDC/USDT/TUSD/yCRV');
    (address baseCFolio, address itemCFolio) =
      _verifyAssetAccess(baseTokenId, tokenId);

    // Validate parameters
    uint256 yPoolAmount = amounts[4];
    require(yPoolAmount > 0, 'yCRV amount is 0');

    // Get single coin and amount
    (int128 stableCoinIndex, uint256 stableCoinAmount) =
      _getStableCoinInfo(amounts);

    // Keep track of how many Y pool tokens were sent
    uint256 balanceBefore = curveYToken.balanceOf(address(this));

    if (stableCoinIndex != -1) {
      // Call to external contract
      curveYDeposit.remove_liquidity_one_coin(
        yPoolAmount,
        stableCoinIndex,
        stableCoinAmount,
        true
      );

      address underlyingCoin =
        curveYDeposit.underlying_coins(int128(stableCoinIndex));
      uint256 underlyingCoinAmount =
        IERC20(underlyingCoin).balanceOf(address(this));

      // Transfer stablecoins back to the sender
      IERC20(underlyingCoin).safeTransfer(_msgSender(), underlyingCoinAmount);
    } else {
      // No stablecoins were passed, sender is withdrawing Y pool tokens directly
      // Transfer Y pool tokens back to the sender
      curveYToken.transfer(_msgSender(), yPoolAmount);
    }

    // Valiate state
    uint256 balanceAfter = curveYToken.balanceOf(address(this));
    require(balanceAfter < balanceBefore, 'Nothing withdrawn');

    // Record assets in Farm contract. They don't earn rewards.
    // removeAsset must only be called from Investment CFolios
    cfolioFarm.removeAssets(itemCFolio, balanceBefore.sub(balanceAfter));

    // Update state
    if (baseTokenId != uint256(-1))
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
    require(cfolio != address(0), 'Invalid c-folio address');

    // Verify that the tokenId is owned by msg.sender in case of direct
    // call or recipient in case of sftMinter call in the SFT contract.
    // This also verifies that the token is not locked in TradeFloor.
    require(
      IERC1155(address(sftHolder)).balanceOf(_msgSender(), sftTokenId) == 1 ||
        (_msgSender() == sftMinter &&
          IERC1155(address(sftHolder)).balanceOf(recipient, sftTokenId) == 1),
      'CFHI: Access denied'
    );

    cfolioFarm.getReward(cfolio, recipient);
  }

  /**
   * @dev See {ICFolioItemHandler-getAmounts}
   *
   * The returned token array is DAI/USDC/USDT/TUSD/yCRV. Tokens are held in
   * this contract as yCRV, so the fifth item will be the amount of yCRV. The
   * four stablecoin amounts are the amount that would be withdrawn if all
   * yCRV were converted to the corresponding stablecoin upon withdrawal. This
   * value is calculated by Curve.
   */
  function getAmounts(address cfolioItem)
    external
    view
    override
    returns (uint256[] memory)
  {
    uint256[] memory result = new uint256[](5);

    uint256 wrappedAmount = cfolioFarm.balanceOf(cfolioItem);

    for (uint256 i = 0; i < 4; ++i) {
      result[i] = curveYDeposit.calc_withdraw_one_coin(
        wrappedAmount,
        int128(i)
      );
    }

    result[4] = wrappedAmount;

    return result;
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

    // get basic data once
    uiData = cfolioFarm.getUIData(address(0));
    // total / rewardDuration / rewardPerDuration
    result = abi.encodePacked(uiData[0], uiData[2], uiData[3]);

    for (uint256 i = 0; i < tokenIds.length; ++i) {
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

  //////////////////////////////////////////////////////////////////////////////
  // Maintanace
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Upgrade contract
   */
  function upgradeContract(CFolioItemHandlerSC newContract) external {
    // Validate access
    require(_msgSender() == admin, 'Admin only');

    // Let new handler control the reward farm
    cfolioFarm.transferOwnership(address(newContract));

    // Dispatch event
    SCContractUpgraded(address(this), address(newContract));

    selfdestruct(payable(address(newContract)));
  }

  /**
   * @dev Set a new SFT minter
   */
  function setMinter(address newMinter) external {
    // Validate access
    require(_msgSender() == admin, 'Admin only');

    // Validate parameters
    require(newMinter != address(0), 'Invalid newMinter');

    // Update state
    sftMinter = newMinter;

    // Dispatch event
    emit NewSCMinter(newMinter);
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
    require(_owners.length == 1 && _ids.length == 1, 'Length must be 1');

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
    require(tokenIds.length == 1, 'Length must be 1');

    // This call originates from the c-folio. We revert if there are investment
    // amounts left for this c-folio address.
    require(cfolioFarm.balanceOf(_msgSender()) == 0, 'CFIH: not empty');
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
    (uint256[] memory tokenIds, uint256 length) =
      IWOWSCryptofolio(cfolio).getCryptofolio(tradeFloor);

    // Marginal increase in gas per item is around 25K. Bounding items to 100
    // fits in sensible gas limits.
    require(length <= 100, 'CFIHSC: Too many items');

    // Calculate new reward amount
    uint256 newRewardAmount = 0;
    for (uint256 i = 0; i < length; ++i) {
      address secondaryCFolio =
        sftHolder.tokenIdToAddress(tokenIds[i].toSftTokenId());
      require(secondaryCFolio != address(0), 'CFIH: Invalid secondary cFolio');

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
      emit SCRewardUpdated(exitingRewardAmount, newRewardAmount);
    } else if (newRewardAmount < exitingRewardAmount) {
      // Update state
      cfolioFarm.removeShares(cfolio, exitingRewardAmount.sub(newRewardAmount));

      // Dispatch event
      emit SCRewardUpdated(exitingRewardAmount, newRewardAmount);
    }
  }

  /**
   * @dev Verifies if an asset access operation is allowed
   *
   * @param baseTokenId Base card tokenId or uint(-1)
   * @param cfolioItemTokenId CFolioItem tokenId handled by this contract
   *
   * A tokenId is "unlocked", if msg.sender is the owner of a tokenId in SFT contract.
   * If baseTokenId is uint(-1), cfolioItemTokenId has to be be unlocked, otherwise
   * baseTokenId has to be unlocked and the locked cfolioItemTokenId inside its cfolio.
   */
  function _verifyAssetAccess(uint256 baseTokenId, uint256 cfolioItemTokenId)
    private
    view
    returns (address, address)
  {
    // Verify it's a cfolioItemTokenId
    require(cfolioItemTokenId.isCFolioCard(), 'CFHI: Not CFolioCard');

    // Verify that the tokenId is one of ours
    address cFolio =
      sftHolder.tokenIdToAddress(cfolioItemTokenId.toSftTokenId());
    require(cFolio != address(0), 'CFIH: Invalid cFolioTokenId');
    require(
      IWOWSCryptofolio(cFolio)._tradefloors(0) == address(this),
      'CFIH: Not our SFT'
    );

    address baseCFolio = address(0);

    if (baseTokenId != uint256(-1)) {
      // Verify it's a cfolio base card
      require(baseTokenId.isBaseCard(), 'CFHI: Not baseCard');
      baseCFolio = sftHolder.tokenIdToAddress(baseTokenId.toSftTokenId());
      require(baseCFolio != address(0), 'CFIH: Invalid baseCFolioTokenId');

      // Verify that the tokenId is owned by msg.sender in SFT contract.
      // This also verifies that the token is not locked in TradeFloor.
      require(
        IERC1155(address(sftHolder)).balanceOf(_msgSender(), baseTokenId) == 1,
        'CFHI: Access denied (B)'
      );

      // Verify that the tokenId is owned by given baseCFolio.
      require(
        IERC1155(address(tradeFloor)).balanceOf(
          baseCFolio,
          cfolioItemTokenId
        ) == 1,
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

  /**
   * @dev Get single coin and amount
   *
   * This is a helper function for {withdraw}. Per the documentation above, no
   * more than one stablecoin amount can be > 0. If more than one stablecoin
   * amount is specified, the revert condition below will be reached.
   *
   * If exactly one stablecoin amount is specified, then the return values will
   * be the index of that coin and its amount.
   *
   * If no stablecoin amounts are > 0, then a coin index of -1 is returned,
   * with a 0 amount.
   *
   * @param amounts The amounts array: DAI/USDC/USDT/TUSD/yCRV
   *
   * @return stableCoinIndex The index of the stablecoin with amount > 0, or -1
   *     if all four stablecoin amounts are 0
   * @return stableCoinAmount The amount of the stablecoin, or 0 if all four
   *     stablecoin amounts are 0
   */
  function _getStableCoinInfo(uint256[] calldata amounts)
    private
    pure
    returns (int128 stableCoinIndex, uint256 stableCoinAmount)
  {
    stableCoinIndex = -1;

    for (uint128 i = 0; i < 4; ++i) {
      if (amounts[i] > 0) {
        require(stableCoinIndex == -1, 'Multiple amounts > 0');
        stableCoinIndex = int8(i);
        stableCoinAmount = amounts[i];
      }
    }
  }
}

