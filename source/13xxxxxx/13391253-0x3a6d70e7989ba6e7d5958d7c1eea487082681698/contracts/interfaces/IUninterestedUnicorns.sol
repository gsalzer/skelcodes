//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IUninterestedUnicorns is IERC721 {
    function mint(uint256 _quantity) external payable;

    function getPrice(uint256 _quantity) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function lockTokens(uint8[] memory tokenId) external;

    function unlockTokens(uint8[] memory tokenId) external;
}

