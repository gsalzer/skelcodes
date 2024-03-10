// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract UzmiToken is ERC20, AccessControl {
    constructor() ERC20("Uzmi Token", "UZMI") {
        _mint(msg.sender, 21000000 * 10 ** decimals());
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}


