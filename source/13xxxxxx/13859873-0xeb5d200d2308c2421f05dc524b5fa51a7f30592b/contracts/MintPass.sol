// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract GuildedGodsMintPass is ERC721, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string _baseUri;
    string _contractUri;
    
    uint public constant MAX_SUPPLY = 6014;
    uint public price = 0.06 ether;
    uint public maxFreeMint = 750;
    uint public maxFreeMintPerWallet = 3;
    bool public isSalesActive = true;
    
    mapping(address => uint) public addressToFreeMinted;

    constructor() ERC721("Guilded Gods Mint Pass", "GG") {
        _contractUri = "ipfs://QmTq75TtkExq178yaKDsK3SnE7Lpj2P9CSzq1f83tLZJvH";
        _baseUri = "ipfs://QmXveyvzunC5ZFwMzcBjMvZDK7s1e3mdRo2zCMcXSdgNEg/";
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }
    
    function freeMint() external {
        require(isSalesActive, "sale is not active");
        require(totalSupply() < maxFreeMint, "theres no free mints remaining");
        require(addressToFreeMinted[msg.sender] < maxFreeMintPerWallet, "caller already minted for free");
        
        addressToFreeMinted[msg.sender]++;
        safeMint(msg.sender);
    }
    
    function mint(uint quantity) external payable {
        require(isSalesActive, "sale is not active");
        require(totalSupply() + quantity <= MAX_SUPPLY, "sold out");
        require(msg.value >= price * quantity, "ether sent is under price");
        
        for (uint i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
    }

    function safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
    
    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current();
    }
    
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }
    
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseUri = newBaseURI;
    }
    
    function setContractURI(string memory newContractURI) external onlyOwner {
        _contractUri = newContractURI;
    }
    
    function toggleSales() external onlyOwner {
        isSalesActive = !isSalesActive;
    }
    
    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }
    
    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
