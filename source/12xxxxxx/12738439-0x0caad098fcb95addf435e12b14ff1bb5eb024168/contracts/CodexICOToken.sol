pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

contract CodexICOToken is ERC20 {
  constructor() public ERC20("CodexICOToken", "CODEXICO") {
    // fifty trillion
    uint256 tokens = 50000000000000 * 10**18;
    console.log("Minting '%s' tokens", tokens);
    _mint(msg.sender, tokens);
  }
}

