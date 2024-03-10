// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts@4.3.3/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.3.3/access/Ownable.sol";
import "@openzeppelin/contracts@4.3.3/utils/Counters.sol";

contract RSALabsCryptoClub is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("RSA Labs Crypto Club 2021", "RSACC") {}
    
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://Qmeud9u7TzTwN5bMd6fHc3537qisyYDBWUmD32u2yxDrGS/";
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
}

