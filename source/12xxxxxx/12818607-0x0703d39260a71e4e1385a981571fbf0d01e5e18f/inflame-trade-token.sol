// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract InflameTradeToken is ERC20, ERC20Burnable, ERC20Permit {
    constructor()
        ERC20("Inflame Trade Token", "IFTT")
        ERC20Permit("Inflame Trade Token")
    {
        _mint(msg.sender, 10000000 * 10 ** decimals());
    }
}

