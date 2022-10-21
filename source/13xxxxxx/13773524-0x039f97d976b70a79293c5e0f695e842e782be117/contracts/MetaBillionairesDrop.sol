// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EARLYMETABILLIONAIRE is ERC1155, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    string public name = "EARLY METABILLIONAIRE";

    constructor() ERC1155("ipfs://QmNqqZ8xMB5d1Enx8L9n2gzfY2P4rQcX1hxFPihtxWJhXL/{id}.json") {
        transferOwnership(msg.sender);
    }

    function mintBatch(address[] calldata addresses) external onlyOwner {
        
        bytes memory data;

        for(uint256 i = 0; i < addresses.length; i++){

            _mint(addresses[i], _tokenIdCounter.current(), 1, data);
            
            _tokenIdCounter.increment();
        }


    }

    function setUri(string calldata _newUri) external onlyOwner{
        _setURI(_newUri);
    }
}

