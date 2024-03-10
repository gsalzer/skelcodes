// SPDX-License-Identifier: MIT
pragma solidity ^0.5.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol";


contract StakeToken is ERC20, ERC20Detailed, ERC20Pausable, ERC20Mintable {
    constructor(uint256 initialSupply) ERC20Detailed("Guarded Ether", "GETH", 18) public {
        _mint(msg.sender, initialSupply);
    }
}

