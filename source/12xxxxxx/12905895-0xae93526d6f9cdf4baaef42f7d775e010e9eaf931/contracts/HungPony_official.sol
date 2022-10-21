// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract HungPony is ERC20, ERC20Burnable {
    constructor() ERC20("Hung Pony", "HUNG") {
        _mint(msg.sender, 7884203284 * 10 ** decimals());
    }
}
