// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EtherWatch is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, AccessControl, Ownable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string private _internalBaseURI;

    event PermanentURI(string _value, uint256 indexed _id);

    constructor(string memory name, string memory symbol, string memory internalBaseURI) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _internalBaseURI = internalBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _internalBaseURI;
    }

    function safeMint(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
        _safeMint(to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory newBaseUri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _internalBaseURI = newBaseUri;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bytes(super._getCustomTokenURI(tokenId)).length == 0, "Custom token URI already set");
        super._setTokenURI(tokenId, _tokenURI);
        emit PermanentURI(_tokenURI, tokenId);
    }
}
