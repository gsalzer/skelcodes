// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

struct MochiInfo {
    address asset;
}

interface IMochiNft is IERC721Enumerable {
    function info(uint256 tokenId) external view returns (MochiInfo memory);
}

