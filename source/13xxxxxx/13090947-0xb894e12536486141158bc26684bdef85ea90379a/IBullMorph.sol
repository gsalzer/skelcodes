// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

import './IERC721.sol';

interface IBullMorph is IERC721 {

    function geneOf(uint256 tokenId) external view returns (uint256 gene);
    function mint() external payable;
    function bulkBuy(uint256 amount) external payable;
    function lastTokenId() external view returns (uint256 tokenId);
    function setPolymorphPrice(uint256 newPolymorphPrice) external virtual;
    function setMaxSupply(uint256 maxSupply) external virtual;
    function setBulkBuyLimit(uint256 bulkBuyLimit) external virtual;

}

