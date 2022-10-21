// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

abstract contract IERC20 {
  function transfer(address to, uint tokens) public virtual returns (bool success);
  function balanceOf(address _sender) public virtual view returns (uint _bal);
  function allowance(address tokenOwner, address spender) public virtual view returns (uint remaining);
  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);
}
