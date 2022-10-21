//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./rarible/royalties/contracts/LibPart.sol";
import "./rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "./rarible/royalties/contracts/LibRoyaltiesV2.sol";


import "hardhat/console.sol";

contract CutOutFest is ERC721URIStorage, RoyaltiesV2Impl, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIDCounter;

    // Base URI
    string private baseTokenURI;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    function _mintFor(address owner) external onlyOwner {
        _tokenIDCounter.increment();     
        _safeMint(owner, _tokenIDCounter.current());
    }

    function _setBaseURI(string memory baseURI) external onlyOwner() {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _setRoyalties(uint _tokenId, address payable _royaltiesReceipientAddress, uint96 _percentageBasisPoints) public onlyOwner {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesReceipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}
