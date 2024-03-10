// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {IDerivative} from '../../derivative/common/interfaces/IDerivative.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {
  ISynthereumPoolOnChainPriceFeed
} from './interfaces/IPoolOnChainPriceFeed.sol';
import {SynthereumPoolOnChainPriceFeed} from './PoolOnChainPriceFeed.sol';
import '../../../@jarvis-network/uma-core/contracts/common/implementation/Lockable.sol';

contract SynthereumPoolOnChainPriceFeedCreator is Lockable {
  //----------------------------------------
  // Public functions
  //----------------------------------------

  /**
   * @notice The derivative's collateral currency must be an ERC20
   * @notice The validator will generally be an address owned by the LP
   * @notice `startingCollateralization should be greater than the expected asset price multiplied
   *      by the collateral requirement. The degree to which it is greater should be based on
   *      the expected asset volatility.
   * @param derivative The perpetual derivative
   * @param finder The Synthereum finder
   * @param version Synthereum version
   * @param roles The addresses of admin, maintainer, liquidity provider
   * @param startingCollateralization Collateralization ratio to use before a global one is set
   * @param fee The fee structure
   * @return poolDeployed Pool contract deployed
   */
  function createPool(
    IDerivative derivative,
    ISynthereumFinder finder,
    uint8 version,
    ISynthereumPoolOnChainPriceFeed.Roles memory roles,
    uint256 startingCollateralization,
    ISynthereumPoolOnChainPriceFeed.Fee memory fee
  )
    public
    virtual
    nonReentrant
    returns (SynthereumPoolOnChainPriceFeed poolDeployed)
  {
    poolDeployed = new SynthereumPoolOnChainPriceFeed(
      derivative,
      finder,
      version,
      roles,
      startingCollateralization,
      fee
    );
  }
}

