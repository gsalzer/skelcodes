// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

interface IOwnable {
  /**
   * @dev Returns the address of the current owner.
   */
  function owner() external view returns (address);
}

