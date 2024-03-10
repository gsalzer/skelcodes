// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract XCXToken is ERC20, Ownable {
    constructor(uint256 initialSupply,uint8 decimals_) public ERC20("CodexToken", "XCX") {
        _setupDecimals(decimals_);
        _mint(msg.sender, initialSupply * (10 ** uint256(decimals())));
    }

}
