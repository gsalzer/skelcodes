// SPDX-License-Identifier: MIT
// Physalis.Finance: Token PHY (DeFi & utility token)

pragma solidity ^0.5.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

contract Physalis is ERC20, ERC20Detailed, Ownable {
  
  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals,
    uint256 _initialSupply
  ) 
    ERC20Detailed(_name, _symbol, _decimals)
    public
  {
    _mint(msg.sender, _initialSupply * 10 ** uint256(_decimals));
  }}

