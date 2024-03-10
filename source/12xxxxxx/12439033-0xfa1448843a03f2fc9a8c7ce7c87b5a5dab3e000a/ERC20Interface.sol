pragma solidity ^0.5.17;

contract ERC20Interface {
  function transfer(address to, uint tokens) public returns (bool success);
  function balanceOf(address _sender) public view returns (uint _bal);
  function allowance(address tokenOwner, address spender) public view returns (uint remaining);
  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);
}
