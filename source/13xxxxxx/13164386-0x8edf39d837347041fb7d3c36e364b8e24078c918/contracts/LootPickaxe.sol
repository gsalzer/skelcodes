// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LootPickaxe is ERC721Enumerable, Ownable, ReentrancyGuard {

    using SafeMath for uint;

    IERC721 loot;
    string internal baseURI;

    constructor(address owner, address lootAddress,string memory tokenBaseUri) ERC721("Pickaxes (for Adventurers)", "LootPickaxe") {
        transferOwnership(owner);
        loot = IERC721(lootAddress);
        baseURI = tokenBaseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata newBaseUri) external onlyOwner {
        baseURI = newBaseUri;
    }

    function price(uint tokenId) public pure returns (uint) {
        require(tokenId > 0, "tokenId starts from 1");
        require(tokenId <= 100, "All pickaxes are minted");
        return tokenId.mul(tokenId).mul(0.001 ether);
    }

    function mint() public payable nonReentrant {
        uint tokenId = totalSupply()+1;
        require(msg.value >= price(tokenId), string(abi.encodePacked('Incorrect ETH value for minting #',Strings.toString(tokenId))));
        require(loot.balanceOf(_msgSender()) > 0, "Only Loot owners can mint");
        _safeMint(_msgSender(), tokenId);
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function tokensIdOf(address owner) public view returns(uint[] memory) {
        uint length = balanceOf(owner);
        uint[] memory tokensId = new uint[](length);
        for(uint i = 0; i < length; i++){
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokensId;
    }
}
