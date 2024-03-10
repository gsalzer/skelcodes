pragma solidity 0.6.12;
// SPDX-License-Identifier: agpl-3.0

import {UserConfiguration} from './UserConfiguration.sol';
import {ReserveConfiguration} from './ReserveConfiguration.sol';
import {ReserveLogic} from './ReserveLogic.sol';
import {IMarginPoolAddressesProvider} from './IMarginPoolAddressesProvider.sol';
import {DataTypes} from './DataTypes.sol';

contract MarginPoolStorage {
  using ReserveLogic for DataTypes.ReserveData;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;

  IMarginPoolAddressesProvider internal _addressesProvider;

  mapping(address => DataTypes.ReserveData) internal _reserves;
  mapping(address => DataTypes.UserConfigurationMap) internal _usersConfig;

  // the list of the available reserves, structured as a mapping for gas savings reasons
  mapping(uint256 => address) internal _reservesList;

  uint256 internal _reservesCount;

  bool internal _paused;
}

