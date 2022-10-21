//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract SpageToken is ERC721Upgradeable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    function initialize() initializer public {
        __ERC721_init("S.page Token", "SPAGE");
        _setBaseURI("https://gateway.s.page/ipfs/");
    }

    function mintNFT(address recipient, string memory tokenIPFS)
        public 
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenIPFS);

        return newItemId;
    }

    function contractURI() public view returns (string memory) {
        return "https://s.page/contract/info.json";
    }
}

