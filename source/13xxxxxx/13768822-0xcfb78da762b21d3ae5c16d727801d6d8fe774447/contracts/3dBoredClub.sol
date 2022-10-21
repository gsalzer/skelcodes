// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MBOT is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _currentSector;
    string private baseURI;
    string private contractURI;

    mapping(uint256 => uint256) private _sectorToPrice;

    constructor(string memory baseUri) ERC721("MonkeyVerse Official", "MBOT") {
        baseURI = baseUri;
        contractURI = "ipfs://QmaKz4qKLEFSb9bCrqYHCHCSfQAbkji25nauJsGc4gQjqo";
        _sectorToPrice[1] = 40000000000000000;
        _sectorToPrice[2] = 60000000000000000;
        _sectorToPrice[3] = 80000000000000000;
        _currentSector.increment();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function mintTo(address receiver, uint256 howMany)
        public
        payable
        returns (uint256[] memory)
    {
        require(_tokenIds.current() + howMany < 2248, "Exceeds max supply");
        uint256 sectorLimit = _currentSector.current() == 1 ? 2 : 10;
        require(
            msg.sender == owner() ||
                balanceOf(receiver) + howMany <= sectorLimit,
            "Exceeds max mint limit"
        );

        uint256 price = _sectorToPrice[_currentSector.current()];
        if (msg.sender == owner() && _currentSector.current() == 1) {
            price = 0;
        }

        require(msg.value >= (price * howMany), "Insufficient funds");

        uint256[] memory newTokenIds = new uint256[](howMany);
        for (uint256 i = 0; i < howMany; i++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();

            _safeMint(receiver, newItemId);
            _handleSectorChange(newItemId);
            newTokenIds[i] = newItemId;
        }
        return newTokenIds;
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "No tokens to withdraw");
        payable(msg.sender).transfer(amount);
    }

    function _handleSectorChange(uint256 currentTokenId) private {
        if (currentTokenId == 50 || currentTokenId == 1200) {
            _currentSector.increment();
        }
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function setBaseURI(string memory baseUri) public onlyOwner {
        baseURI = baseUri;
    }

    function getBaseURI() public view returns (string memory) {
        return baseURI;
    }

    function getCurrentPrice() public view returns (uint256) {
        return _sectorToPrice[_currentSector.current()];
    }

    function getContractURI() public view returns (string memory) {
        return contractURI;
    }

    function setContractURI(string memory newContractURI) public onlyOwner {
        contractURI = newContractURI;
    }
}

