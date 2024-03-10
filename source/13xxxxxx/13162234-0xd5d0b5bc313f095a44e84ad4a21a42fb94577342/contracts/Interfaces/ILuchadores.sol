// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ILuchadores is IERC721 {
    function imageData(uint256 _tokenId) external view returns (string memory);
}

