//SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IPoets is IERC721 {
    function getWordCount(uint256 tokenId) external view returns (uint8);
}

