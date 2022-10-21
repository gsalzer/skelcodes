//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Water is ERC20, Ownable {
    constructor() ERC20("Water", "H2O") {
    }

    function mint(address receiver, uint256 amount) public onlyOwner {
        _mint(receiver, amount);
    }
}
