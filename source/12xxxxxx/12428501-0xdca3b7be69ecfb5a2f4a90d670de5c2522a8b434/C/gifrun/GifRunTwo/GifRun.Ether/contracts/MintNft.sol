pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MintNft is ERC721URIStorage, Ownable{

    using Counters for Counters.Counter;    
    Counters.Counter private _tokenIds;
    
    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol){}
  
    function mintNft(address recipient, string memory tokenUri)
    public
    returns (uint256)
    {
            _tokenIds.increment();

            uint256 tokenId = _tokenIds.current();

            _mint(recipient, tokenId);
            
            _setTokenURI(tokenId, tokenUri);
            
            return tokenId;
    }
    
    
}
