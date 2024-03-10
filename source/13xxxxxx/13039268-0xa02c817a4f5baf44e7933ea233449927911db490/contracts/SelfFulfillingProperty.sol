// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SelfFulfillingProperty is ERC721, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Self Fulfilling Property", "SELF") {}

    function safeMint(address to) public onlyOwner {
        _tokenIdCounter.increment();
        _safeMint(to, _tokenIdCounter.current());
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://bafkreidhwei2cgy4dbdomykydircxjcwbyev2qr6dtbcydj6d7tr2uihmy/";
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io/ipns/k51qzi5uqu5djtkls7l4vxf9nxl2h714omtm7cl8arg64j0sdbnevpcbku4rs2/";
    }
}
