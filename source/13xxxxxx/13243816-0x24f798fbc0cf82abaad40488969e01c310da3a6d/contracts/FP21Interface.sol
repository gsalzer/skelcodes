// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface FP21Interface is IERC721Enumerable {
    function create(uint256 tokenId) external;
    function mintSeries(uint8 num_copies) external;
    function modifyAll() external;
    function transfer(address from, address to, uint256 tokenId) external ;
}
