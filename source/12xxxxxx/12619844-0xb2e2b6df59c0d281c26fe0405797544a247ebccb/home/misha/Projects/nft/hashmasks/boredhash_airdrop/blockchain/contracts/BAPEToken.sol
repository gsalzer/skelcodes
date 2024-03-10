// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";
import "./Token.sol";

/**
 * @title BAPEToken contract
 * @dev Extends my ERC20
 */
contract BAPEToken is Token {
    constructor(address _nftAddress) Token("Bored Ape Token", "BAPE", _nftAddress) {}
}

