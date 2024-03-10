// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../protocol/GoldfinchConfig.sol";

contract TestGoldfinchConfig is GoldfinchConfig {
  function setAddressForTest(uint256 addressKey, address newAddress) public {
    addresses[addressKey] = newAddress;
  }
}

