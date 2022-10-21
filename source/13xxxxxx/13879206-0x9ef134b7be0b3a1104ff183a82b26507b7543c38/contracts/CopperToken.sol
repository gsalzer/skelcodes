pragma solidity ^0.5.5;

////////////////////////////////////////////////
//////// Deploy peg63.546u Copper token ////////
////////////////////////////////////////////////
//
// =============================================
// Name:         peg63.546u Copper
// Symbol:       CU
// Total supply: Will be set after the Crowdsale
// =============================================

import "@openzeppelin/contracts@2.5.0/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@2.5.0/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts@2.5.0/token/ERC20/ERC20Mintable.sol";

contract CopperToken is ERC20, ERC20Detailed, ERC20Mintable {
    constructor() public ERC20Detailed("peg63.546u", "CU", 18) {}
}
