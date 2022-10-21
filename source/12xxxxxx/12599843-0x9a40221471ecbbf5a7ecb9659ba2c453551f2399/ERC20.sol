// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
 * @title ERC20
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
abstract contract ERC20 {
  uint256 public totalSupply;

  function balanceOf(address who) public virtual view returns (uint256);
  function transfer(address to, uint256 value) public virtual returns (bool);
  function allowance(address owner, address spender) public virtual view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public virtual returns (bool);
  function approve(address spender, uint256 value) public virtual returns (bool);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
