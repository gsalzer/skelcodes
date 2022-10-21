/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '../../0xerc1155/interfaces/IERC20.sol';
import '../../0xerc1155/utils/SafeERC20.sol';
import '../../interfaces/curve/CurveDepositInterface.sol';

import './CFolioItemHandlerFarm.sol';

/**
 * @dev CFolioItemHandlerSC manages CFolioItems, minted in the SFT contract.
 *
 * See {CFolioItemHandlerFarm}.
 */
contract CFolioItemHandlerSC is CFolioItemHandlerFarm {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  //////////////////////////////////////////////////////////////////////////////
  // Routing
  //////////////////////////////////////////////////////////////////////////////

  // Curve Y pool token contract
  IERC20 public immutable curveYToken;

  // Curve Y pool deposit contract
  ICurveFiDepositY public immutable curveYDeposit;

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
  constructor(IAddressRegistry addressRegistry)
    CFolioItemHandlerFarm(addressRegistry, AddressBook.BOIS_REWARDS)
  {
    // The Y pool deposit contract
    curveYDeposit = ICurveFiDepositY(
      addressRegistry.getRegistryEntry(AddressBook.CURVE_Y_DEPOSIT)
    );

    // The Y pool token contract
    curveYToken = IERC20(
      addressRegistry.getRegistryEntry(AddressBook.CURVE_Y_TOKEN)
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
  // Implementation of {CFolioItemHandlerFarm}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {CFolioItemHandlerFarm-_deposit}.
   */
  function _deposit(
    address itemCFolio,
    address payer,
    uint256[] calldata amounts
  ) internal override {
    // Validate input
    require(amounts.length == 5, 'CFIHSC: Amount length invalid');

    // Keep track of how many Y pool tokens were received
    uint256 beforeBalance = curveYToken.balanceOf(address(this));

    // Keep track of amounts
    uint256[4] memory stableAmounts;
    uint256 totalStableAmount;

    // Update state
    for (uint256 i = 0; i < 4; ++i) {
      address underlyingCoin = curveYDeposit.underlying_coins(int128(i));

      IERC20(underlyingCoin).safeTransferFrom(payer, address(this), amounts[i]);

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
        'CFIHSC: No stable liquidity'
      );
    }

    // Handle Y pool
    uint256 yPoolAmount = amounts[4];

    // Update state
    if (yPoolAmount > 0) {
      curveYToken.safeTransferFrom(payer, address(this), yPoolAmount);
    }

    // Validate state
    uint256 afterBalance = curveYToken.balanceOf(address(this));
    require(afterBalance > beforeBalance, 'CFIFSC: No investment');

    // Record assets in Farm contract. They don't earn rewards.
    //
    // NOTE: {addAssets} must only be called from Investment CFolios. This
    // call is allowed without any investment.
    cfolioFarm.addAssets(itemCFolio, afterBalance.sub(beforeBalance));
  }

  /**
   * @dev See {CFolioItemHandlerFarm-_withdraw}
   *
   * Note: tokenId can be owned by a base SFT. In this case, the base SFT
   * cannot be locked.
   *
   * There is only need to update rewards if tokenId is part of an unlocked
   * base SFT.
   *
   * @param itemCFolio The address of the target CFolioItem cryptofolio
   * @param amounts The amounts, with the tokens being DAI/USDC/USDT/TUSD/yCRV.
   *     yCRV must be specified, as yCRV tokens are held by this contract.
   *     If all four stablecoin amounts are 0, then yCRV is withdrawn to the
   *     sender's wallet. If exactly one of the four stablecoin amounts is > 0,
   *     then yCRV will be converted to the specified stablecoin. The amount in
   *     the array is the minimum amount of stablecoin tokens that must be
   *     withdrawn.
   */
  function _withdraw(address itemCFolio, uint256[] calldata amounts)
    internal
    override
  {
    // Validate input
    require(amounts.length == 5, 'CFIHSC: Amount length invalid');

    // Validate parameters
    uint256 yPoolAmount = amounts[4];
    require(yPoolAmount > 0, 'CFIHSC: yCRV amount is 0');

    // Get single coin and amount
    (int128 stableCoinIndex, uint256 stableCoinAmount) = _getStableCoinInfo(
      amounts
    );

    // Keep track of how many Y pool tokens were sent
    uint256 balanceBefore = curveYToken.balanceOf(address(this));

    // Update state
    if (stableCoinIndex != -1) {
      // Call to external contract
      curveYDeposit.remove_liquidity_one_coin(
        yPoolAmount,
        stableCoinIndex,
        stableCoinAmount,
        true
      );

      address underlyingCoin = curveYDeposit.underlying_coins(
        int128(stableCoinIndex)
      );
      uint256 underlyingCoinAmount = IERC20(underlyingCoin).balanceOf(
        address(this)
      );

      // Transfer stablecoins back to the sender
      IERC20(underlyingCoin).safeTransfer(_msgSender(), underlyingCoinAmount);
    } else {
      // No stablecoins were passed, sender is withdrawing Y pool tokens directly
      // Transfer Y pool tokens back to the sender
      curveYToken.safeTransfer(_msgSender(), yPoolAmount);
    }

    // Valiate state
    uint256 balanceAfter = curveYToken.balanceOf(address(this));
    require(balanceAfter < balanceBefore, 'Nothing withdrawn');

    // Record assets in Farm contract. They don't earn rewards.
    //
    // NOTE: {removeAssets} must only be called from Investment CFolios.
    cfolioFarm.removeAssets(itemCFolio, balanceBefore.sub(balanceAfter));
  }

  /**
   * @dev See {CFolioItemHandlerFarm-_verifyTransferTarget}
   */
  function _verifyTransferTarget(uint256 baseSftTokenId)
    internal
    view
    override
  {
    (, uint8 level) = sftHolder.getTokenData(baseSftTokenId);

    require((LEVEL2BOIS & (uint256(1) << level)) > 0, 'CFIHSC: Bois only');
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {ICFolioItemHandler} via {CFolioItemHandlerFarm}
  //////////////////////////////////////////////////////////////////////////////

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

  //////////////////////////////////////////////////////////////////////////////
  // Implementation details
  //////////////////////////////////////////////////////////////////////////////

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

