// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IEnumerableContract is IERC721 {

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function burn(uint256 tokenId) external;
}
