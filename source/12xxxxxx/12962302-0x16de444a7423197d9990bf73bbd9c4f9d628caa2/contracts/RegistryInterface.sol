// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

interface RegistryInterface {
  function lookup() external view returns (address);
}
