// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

import "./opensea/ERC721Tradable.sol";

/**
 * @title PieceHairFlip
 * PieceHairFlip - a contract for my puzzle piece.
 */
contract PieceHairFlip is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("PieceHairFlip", "GWPHF", _proxyRegistryAddress)
    {}

    function baseTokenURI() public pure override returns (string memory) {
        return "https://www.grannywolf.com/api/pieces/hair-flip/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://www.grannywolf.com/api/contracts/hair-flip";
    }
}

