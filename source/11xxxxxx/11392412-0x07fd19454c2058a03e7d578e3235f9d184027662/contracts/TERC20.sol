// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract TERC20 is ERC20, Ownable {
    using SafeMath for uint256;

    constructor(
        string memory name,
        string memory symbol,
        uint256 sypply
    ) public ERC20(name, symbol) Ownable() {
        if (sypply > 0) {
            _mint(owner(), sypply * 10**uint256(decimals()));
        }
    }
}

