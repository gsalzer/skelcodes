// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {IDerivative} from '../../derivative/common/interfaces/IDerivative.sol';
import {ISynthereumFinder} from '../../versioning/interfaces/IFinder.sol';
import {ISynthereumPool} from './interfaces/IPool.sol';
import {SynthereumPool} from './Pool.sol';
import '../../../@jarvis-network/uma-core/contracts/common/implementation/Lockable.sol';

contract SynthereumPoolCreator is Lockable {
  function createPool(
    IDerivative derivative,
    ISynthereumFinder finder,
    uint8 version,
    ISynthereumPool.Roles memory roles,
    bool isContractAllowed,
    uint256 startingCollateralization,
    ISynthereumPool.Fee memory fee
  ) public virtual nonReentrant returns (SynthereumPool poolDeployed) {
    poolDeployed = new SynthereumPool(
      derivative,
      finder,
      version,
      roles,
      isContractAllowed,
      startingCollateralization,
      fee
    );
  }
}

