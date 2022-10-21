// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import {ISynthereumPoolRegistry} from './interfaces/IPoolRegistry.sol';
import {ISynthereumFinder} from './interfaces/IFinder.sol';
import {IERC20} from '../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SynthereumInterfaces} from './Constants.sol';
import {
  EnumerableSet
} from '../../@openzeppelin/contracts/utils/EnumerableSet.sol';
import {
  Lockable
} from '../../@jarvis-network/uma-core/contracts/common/implementation/Lockable.sol';

contract SynthereumPoolRegistry is ISynthereumPoolRegistry, Lockable {
  using EnumerableSet for EnumerableSet.AddressSet;

  ISynthereumFinder public synthereumFinder;

  mapping(string => mapping(IERC20 => mapping(uint8 => EnumerableSet.AddressSet)))
    private symbolToPools;

  EnumerableSet.AddressSet private collaterals;

  constructor(ISynthereumFinder _synthereumFinder) public {
    synthereumFinder = _synthereumFinder;
  }

  function registerPool(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 poolVersion,
    address pool
  ) external override nonReentrant {
    address deployer =
      ISynthereumFinder(synthereumFinder).getImplementationAddress(
        SynthereumInterfaces.Deployer
      );
    require(msg.sender == deployer, 'Sender must be Synthereum deployer');
    symbolToPools[syntheticTokenSymbol][collateralToken][poolVersion].add(pool);
    collaterals.add(address(collateralToken));
  }

  function isPoolDeployed(
    string calldata poolSymbol,
    IERC20 collateral,
    uint8 poolVersion,
    address pool
  ) external view override nonReentrantView returns (bool isDeployed) {
    isDeployed = symbolToPools[poolSymbol][collateral][poolVersion].contains(
      pool
    );
  }

  function getPools(
    string calldata poolSymbol,
    IERC20 collateral,
    uint8 poolVersion
  ) external view override nonReentrantView returns (address[] memory) {
    EnumerableSet.AddressSet storage poolSet =
      symbolToPools[poolSymbol][collateral][poolVersion];
    uint256 numberOfPools = poolSet.length();
    address[] memory pools = new address[](numberOfPools);
    for (uint256 j = 0; j < numberOfPools; j++) {
      pools[j] = poolSet.at(j);
    }
    return pools;
  }

  function getCollaterals()
    external
    view
    override
    nonReentrantView
    returns (address[] memory)
  {
    uint256 numberOfCollaterals = collaterals.length();
    address[] memory collateralAddresses = new address[](numberOfCollaterals);
    for (uint256 j = 0; j < numberOfCollaterals; j++) {
      collateralAddresses[j] = collaterals.at(j);
    }
    return collateralAddresses;
  }
}

