// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OxyToken is ERC20("OxySwap Token", "OXY"), Ownable {

    constructor() public {
        _mint(msg.sender, 10 ** 8 * 10 ** 18);
        _setupDecimals(18);
    }
}

