// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

interface IBlitmap is IERC721Enumerable {
    function tokenSvgDataOf(uint256 tokenId) external view returns (string memory);
    function tokenDataOf(uint256 tokenId) external view returns (bytes memory);
}
