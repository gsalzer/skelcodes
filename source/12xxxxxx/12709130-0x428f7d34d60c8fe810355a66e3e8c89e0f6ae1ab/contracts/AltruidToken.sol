//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AltruidToken is ERC20
{
    uint256 private constant INITIAL_SUPPLY = 10 ** 8; // 100M

    constructor() public ERC20("Altruid", "ALTD") {
        console.log("Deploying: %s (%s) with %d initial supply", name(), symbol(), INITIAL_SUPPLY);
        _mint(msg.sender, INITIAL_SUPPLY * (10 ** uint256(decimals())));
    }
}

