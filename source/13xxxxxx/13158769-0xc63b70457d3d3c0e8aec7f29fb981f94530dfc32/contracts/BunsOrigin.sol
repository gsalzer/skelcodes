// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BUNSLANDOrigin is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    address private bank = 0x74CaD1e8e7a81215857ce194540dA21d29Ae22a2;
    bool public hasSaleStarted = false;
    uint256 public constant bunsPrice = 0.02 ether;

    constructor() ERC721("BUNS.LAND Origin", "BUNSO") {}

    function safeMint(address to, uint256 numBuns) public payable {
    	require(hasSaleStarted, "Sale has not started.");
        require(numBuns == 1 || numBuns == 6, "You can mint 1 bun or a box of 6 buns.");
        require(msg.value >= bunsPrice * numBuns, "Not enough ETH sent; check price!");

        for (uint i = 0; i < numBuns; i++) {
            _tokenIdCounter.increment();
            _safeMint(to, _tokenIdCounter.current());
        }
    }

    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }

    function stopSale() public onlyOwner {
        hasSaleStarted = false;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://nfts.buns.land/bunso/";
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

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;

        require(payable(bank).send(_balance));
    }
}



