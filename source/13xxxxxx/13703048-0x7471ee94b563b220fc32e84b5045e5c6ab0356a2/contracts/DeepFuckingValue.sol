// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract DeepFuckingValue is ERC20, ERC20Burnable {
    constructor() ERC20("DeepFuckingValue", "DFV") {
        _mint(msg.sender, 1000000000000000 * 10 ** decimals());
    }
}
