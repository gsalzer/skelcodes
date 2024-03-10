// contracts/AuthToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract AuthToken is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address public owner;

    constructor() ERC721("Auth", "AUTH") {
        owner = msg.sender;
    }

    function authItem(string memory tokenURI)
        public
        returns (uint256)
    {
        require(msg.sender == owner, "Only owner can call this function.");

        _tokenIds.increment();

        uint256 newAuthId = _tokenIds.current();
        _mint(msg.sender, newAuthId);
        _setTokenURI(newAuthId, tokenURI);

        return newAuthId;
    }
}

