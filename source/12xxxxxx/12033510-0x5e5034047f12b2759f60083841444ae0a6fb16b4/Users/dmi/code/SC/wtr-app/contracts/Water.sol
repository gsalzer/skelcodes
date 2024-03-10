// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Water
 */
contract Water is Ownable, ERC20 {
    uint256 public initialSupply = 0;

    constructor() ERC20("Water", "WTR") public {}

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }
}
