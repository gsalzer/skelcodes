// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {SynthereumRegistry} from './Registry.sol';
import {ISynthereumFinder} from '../interfaces/IFinder.sol';

/**
 * @title Register and track all the pools deployed
 */
contract SynthereumPoolRegistry is SynthereumRegistry {
  /**
   * @notice Constructs the SynthereumPoolRegistry contract
   * @param _synthereumFinder Synthereum finder contract
   */
  constructor(ISynthereumFinder _synthereumFinder)
    public
    SynthereumRegistry('POOL REGISTRY', _synthereumFinder)
  {}
}

