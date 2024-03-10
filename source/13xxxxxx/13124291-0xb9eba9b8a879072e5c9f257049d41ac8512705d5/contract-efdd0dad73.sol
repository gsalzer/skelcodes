// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts@4.3.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.3.0/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.3.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.3.0/utils/Counters.sol";

contract Blankies is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    
    uint constant public maxSupply = 128;
    uint public claimPrice = 3 ether;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Blankies", "BLANK") {
    }

    function safeMint(address to) public onlyOwner {
        require(_tokenIdCounter.current() < maxSupply);
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }
    
    function mintMany(uint amount) public payable {
        uint totalValue = amount * claimPrice;
        require(msg.value == totalValue);
        payable(owner()).transfer(msg.value);
        
        for (uint i=0; i<amount; i++) {
            require(_tokenIdCounter.current() < maxSupply);
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }
    
    function getCurrent() external view returns(uint) {
        return _tokenIdCounter.current();
    }

    // The following functions are overrides required by Solidity.

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
}

