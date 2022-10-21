pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Penguins02138 is ERC721URIStorage, Ownable {
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function mint(address _to, uint256 _tokenId, string memory _tokenUri) external onlyOwner {
        _mint(_to, _tokenId);
        _setTokenURI(_tokenId, _tokenUri);
    }
}

