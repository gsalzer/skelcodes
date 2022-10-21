/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

import '@openzeppelin/contracts/access/Ownable.sol';

import './interfaces/IAddressRegistry.sol';

pragma solidity >=0.7.0 <0.8.0;

contract AddressRegistry is IAddressRegistry, Ownable {
  mapping(bytes32 => address) public registry;

  constructor(address _owner) {
    transferOwnership(_owner);
  }

  function setRegistryEntry(bytes32 _key, address _location)
    external
    override
    onlyOwner
  {
    registry[_key] = _location;
  }

  function getRegistryEntry(bytes32 _key)
    external
    view
    override
    returns (address)
  {
    require(registry[_key] != address(0), 'no address for key');
    return registry[_key];
  }
}

