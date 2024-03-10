// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract OutkastSpecials is Ownable, ERC721 {
    string private _outkastBaseURI = "";

    uint256 public totalSupply = 0;

    constructor() ERC721("OutkastSpecials", "OKS") {}

    function mintSpecials(address[] calldata winners) external onlyOwner {
        for (uint256 i = 0; i < winners.length; i++) {
            _safeMint(winners[i], totalSupply + i + 1);
        }

        totalSupply += winners.length;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://outkast.world/specials/metadata/";
    }
}
