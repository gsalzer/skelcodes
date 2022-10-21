// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC721WithOverrides.sol";

contract RunePunks is ERC721WithOverrides {
    
    using SafeMath for uint;
    uint public numMinted; 
    string ipfsURI;

    constructor() ERC721("RunePunks", "RUNEPUNK") {
        ipfsURI = "https://ipfs.io/ipfs/QmWtsGDah9SjUWb8XcUcVJ48XvGoKQx5UBHVwjjtyumrfp";
    }

    function mint() public {
        uint mintIndex = numMinted;
        _safeMint(msg.sender, mintIndex);
        _setTokenURI(mintIndex, ipfsURI);    
        numMinted = numMinted.add(1);
    }
    
    /**
        Get rares owned by address.
     */
    function tokensOfOwner(address _owner) public view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    /////////////////////////////////
    ///// Only owner functions /////
    /////////////////////////////////

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}

