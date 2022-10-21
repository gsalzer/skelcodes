// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IShogunNFT is IERC721Enumerable {
    function seppuku(uint256 _tokenId) external;
}
