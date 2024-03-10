// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract TokenTesting is ERC20, Ownable {
    using SafeMath for uint256;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _supply
    ) public ERC20(_name, _symbol) Ownable() {
        _mint(owner(), _supply * 10**uint256(decimals()));
    }
}

