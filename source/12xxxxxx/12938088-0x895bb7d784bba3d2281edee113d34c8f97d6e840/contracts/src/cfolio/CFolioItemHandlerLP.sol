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

import './CFolioItemHandlerFarm.sol';

/**
 * @dev CFolioItemHandlerLP manages CFolioItems, minted in the SFT contract.
 *
 * See {CFolioItemHandlerFarm}.
 */
contract CFolioItemHandlerLP is CFolioItemHandlerFarm {
  using SafeERC20 for IERC20;

  //////////////////////////////////////////////////////////////////////////////
  // Routing
  //////////////////////////////////////////////////////////////////////////////

  // The token staked here (WOWS/WETH UniV2 Pair)
  IERC20 public immutable stakingToken;

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Constructs the CFolioItemHandlerLP
   *
   * We gather all current addresses from address registry into immutable vars.
   * If one of the relevant addresses changes, the contract has to be updated.
   * There is little state here, user state is completely handled in CFolioFarm.
   */
  constructor(IAddressRegistry addressRegistry)
    CFolioItemHandlerFarm(addressRegistry, AddressBook.WOLVES_REWARDS)
  {
    // The ERC-20 token we stake
    stakingToken = IERC20(
      addressRegistry.getRegistryEntry(AddressBook.UNISWAP_V2_PAIR)
    );
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
    // Validate parameters
    require(amounts.length == 1 && amounts[0] > 0, 'CFIHLP: invalid amount');
    // Transfer LP token to this contract
    stakingToken.safeTransferFrom(payer, address(this), amounts[0]);

    // Record assets in the Farm contract. They don't earn rewards.
    //
    // NOTE: {addAssets} must only be called from investment CFolios.
    cfolioFarm.addAssets(itemCFolio, amounts[0]);
  }

  /**
   * @dev See {CFolioItemHandlerFarm-_withdraw}.
   */
  function _withdraw(address itemCFolio, uint256[] calldata amounts)
    internal
    override
  {
    // Validate parameters
    require(amounts.length == 1 && amounts[0] > 0, 'CFIHLP: invalid amount');

    // Record assets in Farm contract. They don't earn rewards.
    //
    // NOTE: {removeAssets} must only be called from Investment CFolios.
    cfolioFarm.removeAssets(itemCFolio, amounts[0]);

    // Transfer LP token from this contract.
    stakingToken.safeTransfer(_msgSender(), amounts[0]);
  }

  /**
   * @dev Verify if target base SFT is allowed
   */
  function _verifyTransferTarget(uint256 baseSftTokenId)
    internal
    view
    override
  {
    (, uint8 level) = sftHolder.getTokenData(baseSftTokenId);

    require((LEVEL2WOLF & (uint256(1) << level)) > 0, 'CFIHLP: Wolves only');
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {ICFolioItemHandler} via {CFolioItemHandlerFarm}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {ICFolioItemHandler-getAmounts}
   */
  function getAmounts(address cfolioItem)
    external
    view
    override
    returns (uint256[] memory)
  {
    uint256[] memory result = new uint256[](1);

    result[0] = cfolioFarm.balanceOf(cfolioItem);

    return result;
  }
}

