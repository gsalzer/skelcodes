pragma solidity ^0.7.3;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RedditAvatarNFTs is ERC721, Ownable {
  constructor() public ERC721("RedditNFT", "SNOO") {}

  function mintNFT(uint tokenId, address ownerId, string memory tokenURI) public onlyOwner {
    _mint(ownerId, tokenId);
    _setTokenURI(tokenId, tokenURI);
  }
}

