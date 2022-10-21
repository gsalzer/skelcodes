pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OCC is ERC20 {
  constructor() public ERC20("Octopus VC token", "OCC") {
    _mint(msg.sender, 20000000000000000000000000);
  }
}


