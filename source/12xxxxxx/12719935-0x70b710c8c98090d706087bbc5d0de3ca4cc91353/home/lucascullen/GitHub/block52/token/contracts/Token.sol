// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is IERC20, ERC20, Ownable {
  
  constructor() ERC20("Block52", "B52") {
    _mint(0x9572E2a1DF6CE89a632dA4d29d6b48453F505e85, 52000000000000000000000000);
  }
}
