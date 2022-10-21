// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Token is ERC20, Ownable {

    constructor(string memory name, string memory symbol, uint supply, address owner) ERC20(name, symbol) {
        _mint(owner, supply);
        Ownable.transferOwnership(owner);
    }

    function mint(address account, uint amount) public onlyOwner {
        _mint(account, amount);
    }
}

