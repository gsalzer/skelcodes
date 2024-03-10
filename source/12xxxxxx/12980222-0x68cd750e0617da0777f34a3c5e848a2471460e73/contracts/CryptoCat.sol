// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol";

contract CryptoCat is ERC20, ERC20FlashMint {
    constructor() ERC20("CryptoCat", "MEOW") {
        _mint(msg.sender, 9999999 * 10 ** decimals());
    }
}

