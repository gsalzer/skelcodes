pragma solidity ^0.5.7;

import "./ERC20Standart.sol";

contract Amazying is ERC20Standard {
 constructor() public {
  totalSupply = 1000000000;
  name = "AmazYing";
  decimals = 8;
  symbol = "AMZ";
  balances[0xBa23A08356f1F663dC630a14577D21179c62384B] = totalSupply;
 }
}

