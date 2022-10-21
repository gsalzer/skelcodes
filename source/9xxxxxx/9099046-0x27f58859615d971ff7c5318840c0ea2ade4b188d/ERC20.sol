/**
 * Source Code first verified at https://etherscan.io on Wednesday, March 13, 2019
 (UTC) */

pragma solidity 0.5.7;

contract ERC20 {
  function totalSupply()public view returns (uint256 total_Supply);
  function balanceOf(address who)public view returns (uint256);
  function transfer(address to, uint256 value)public returns (bool success);
  function transferFrom(address from, address to, uint256 value)public returns (bool success);
  function approve(address spender, uint256 value)public returns (bool success);
  function allowance(address owner, address spender)public view returns (uint256 remaining);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

