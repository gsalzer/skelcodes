// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../contracts/OpenZeppelin/contracts/token/ERC721/ERC721.sol";

contract NFT is ERC721 {
    string tokenUri;

    constructor(string memory _tokenUri, address artist) ERC721("Crafting with Ether", "CWE") {
        _safeMint(artist, 1);
        tokenUri = _tokenUri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require((tokenId == 1), "ERC721URIStorage: URI query for nonexistent token");
        return tokenUri;
    }
}
