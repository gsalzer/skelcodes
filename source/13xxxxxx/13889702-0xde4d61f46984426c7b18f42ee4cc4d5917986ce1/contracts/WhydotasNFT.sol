// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WhydotasNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string private __baseURI = "https://www.whydotas.com/nft/";

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    constructor(address _owner) ERC721("Whydotas NFT", "Whydotas") {
        _transferOwnership(_owner);
    }

    function mintWithTokenURI(string memory tokenUri) public onlyOwner returns (uint256 tokenId) {
        (tokenId) = mint();
        setTokenURI(tokenId, tokenUri);
    }

    function mint() public onlyOwner returns (uint256 tokenId) {
        tokenId = totalSupply() + 1;
        _safeMint(_msgSender(), tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // If token URI set, return it.
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        // Fallback to url concated from base uri and token id.
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    function setBaseUri(string memory uri) public onlyOwner {
        __baseURI = uri;
    }
}

