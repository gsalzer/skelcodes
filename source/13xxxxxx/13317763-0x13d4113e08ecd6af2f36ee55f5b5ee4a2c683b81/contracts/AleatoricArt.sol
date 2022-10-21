// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract AleatoricArt is Context, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    string private _baseTokenURI;

    constructor(
        string memory baseTokenURI
    ) ERC721("aleatoric.art", "ZZZ") {
        _baseTokenURI = baseTokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    function setBaseURI(string memory _newBaseURI) public virtual onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    function mint(address to) public virtual onlyOwner {
        _mint(to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }
}
