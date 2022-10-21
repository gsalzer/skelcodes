// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

interface ERC20 {
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
}

