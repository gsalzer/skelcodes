// SPDX-License-Identifier: MIT
pragma solidity ^0.5.8;

/**
 * @title ERC20Basic
 * @dev Simple version of ERC20 interface
 * @notice https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  /**
   * total supply
   */
  uint256 public totalSupply;

  /**
   * balance of address
   */
  function balanceOf(address who) public view returns (uint256);

  /**
   * transfer value to address
   */
  function transfer(address to, uint256 value) public returns (bool);

  /**
   * Transfer event
   */
  event Transfer(address indexed from, address indexed to, uint256 value);
}

