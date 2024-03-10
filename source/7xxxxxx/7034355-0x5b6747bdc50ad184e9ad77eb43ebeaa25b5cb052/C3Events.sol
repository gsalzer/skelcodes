pragma solidity ^0.5.0 <0.6.0;

contract C3Events {
  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

