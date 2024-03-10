// SPDX-License-Identifier: MIT

/**
 * Copyright 2021, Bitlabs Pte. Ltd. All Rights Reserved.
 */
 

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/utils/Strings.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/utils/Counters.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract ARTHAUS is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 private _maxSupply = 1000;
    using Strings for uint256;

    string public ARTHAUS_PROVENANCE = "02e9a1bc0ce42d406ed59dbdcf82421c";
    string public ARTWORK_CREATOR = "Nicholas Keays";
    
    constructor() ERC721("ART HAUS", "ARTHAUS") {}

    function safeMint(uint256 numberOfKeys, address to) public onlyOwner {
        require(totalSupply() < _maxSupply, "Minting would exceed max supply of keys");
        require(numberOfKeys > 0, "Cannot mint 0 keys");
    
        for (uint i = 0; i < numberOfKeys; i++) {
        uint mintIndex = totalSupply();

        require(mintIndex < _maxSupply, "Exceeds max number of keys in existence");

        _safeMint(to, mintIndex);
        _tokenIdCounter.increment();
        }
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://bafkreieq7hqvdka3shjednygevqhb26lqit6uvtpxnynm6wllit7x6luyu?tokenId=";
    }

     function maxSupply() public view returns (uint256){
        return _maxSupply;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
