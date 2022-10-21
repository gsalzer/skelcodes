// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract GM is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string[] public tokenURIs;
    uint256 public uriIndex = 0;

    bool public minted = false;

    constructor() ERC721("GM!", "GM!") {}

    function safeMint(address to) public onlyOwner {
        require(!minted);
        _safeMint(to, _tokenIdCounter.current());
        minted = true;
        _tokenIdCounter.increment();
    }

    function addURI(string memory uri) public onlyOwner {
        tokenURIs.push(uri);
    }

    function changeTokenURI(uint256 index) public {
        require(_msgSender() == ERC721.ownerOf(0), "You are not the owner");
        require(index < tokenURIs.length, "URI index out of range");
        uriIndex = index;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns
    (string memory) {
        require(tokenURIs.length > 0, "Token URI not specified");
        return tokenURIs[uriIndex];
    }
}

