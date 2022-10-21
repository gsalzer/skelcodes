// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTBillboardToken is ERC721, Ownable {
    constructor () ERC721("NFT Billboard Token", "NFTBT") Ownable() {
        _safeMint(msg.sender, 0);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://the-nft-billboard.com/metadata.json?tokenId=";
    }
}

