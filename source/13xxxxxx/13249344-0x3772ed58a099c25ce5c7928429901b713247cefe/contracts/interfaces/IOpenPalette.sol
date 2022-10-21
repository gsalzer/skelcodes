// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IOpenPalette is IERC721Enumerable, IERC721Metadata {
    function getColor1(uint256 tokenId) external view returns (uint256);

    function getColor2(uint256 tokenId) external view returns (uint256);

    function getColor3(uint256 tokenId) external view returns (uint256);

    function getColor4(uint256 tokenId) external view returns (uint256);

    function getColor5(uint256 tokenId) external view returns (uint256);
}

