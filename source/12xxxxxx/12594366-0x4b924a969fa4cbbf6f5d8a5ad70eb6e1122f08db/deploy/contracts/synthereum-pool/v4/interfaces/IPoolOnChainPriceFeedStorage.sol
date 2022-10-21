// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import {IERC20} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISynthereumPoolOnChainPriceFeed} from './IPoolOnChainPriceFeed.sol';
import {ISynthereumFinder} from '../../../core/interfaces/IFinder.sol';
import {EnumerableSet} from '../../../../@openzeppelin/contracts/utils/EnumerableSet.sol';
import {
  FixedPoint
} from '../../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';

interface ISynthereumPoolOnChainPriceFeedStorage {
  struct Storage {
    // Synthereum finder
    ISynthereumFinder finder;
    // Synthereum version
    uint8 version;
    // Collateral token
    IERC20 collateralToken;
    // Synthetic token
    IERC20 syntheticToken;
    // Derivatives supported
    EnumerableSet.AddressSet derivatives;
    // Starting collateralization ratio
    FixedPoint.Unsigned startingCollateralization;
    // Fees
    ISynthereumPoolOnChainPriceFeed.Fee fee;
    // Used with individual proportions to scale values
    uint256 totalFeeProportions;
    // Price identifier
    bytes32 priceIdentifier;
  }
}

