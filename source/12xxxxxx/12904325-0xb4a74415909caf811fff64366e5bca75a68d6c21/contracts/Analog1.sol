// contracts/Analog1.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Analog is ERC20Burnable, Ownable {

    constructor(uint256 initialSupply) ERC20("Analog", "ANLOG") {
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint amount) external onlyOwner {
        _mint(to, amount);
    }
}
