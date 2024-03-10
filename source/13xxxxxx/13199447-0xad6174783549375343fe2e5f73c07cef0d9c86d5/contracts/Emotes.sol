/*
███████ ███    ███  ██████  ████████ ███████ ███████ 
██      ████  ████ ██    ██    ██    ██      ██      
█████   ██ ████ ██ ██    ██    ██    █████   ███████ 
██      ██  ██  ██ ██    ██    ██    ██           ██ 
███████ ██      ██  ██████     ██    ███████ ███████                                                                                                           
................ (for Adventurers) .................                        
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Emotes is ERC721Enumerable, Pausable, Ownable {

    string private _tokenBaseURI;

    constructor(string memory tokenBaseURI) ERC721("Emotes (for Adventurers)", "EMOTES") {
        _tokenBaseURI = tokenBaseURI;
        _pause(); // Start contract paused
    }
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function claim(uint256 tokenId) external whenNotPaused {
        require(tokenId >= 1 && tokenId <= 10000, "Token ID invalid");
        require(balanceOf(_msgSender()) <= 10, "Max 10 per wallet");
        _mint(_msgSender(), tokenId);
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _tokenBaseURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }
}
