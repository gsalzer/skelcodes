// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import "../libraries/LibPart.sol"; 

interface RoyaltiesV2 {
    event RoyaltiesSet(uint256 tokenId, LibPart.Part royalties);
    function getPaceArtV2Royalties(uint256 id) external view returns (LibPart.Part memory);
}
