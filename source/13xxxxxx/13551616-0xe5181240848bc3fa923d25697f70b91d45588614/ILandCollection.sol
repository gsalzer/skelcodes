// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface ILandCollection {
  function totalMinted(uint256 groupId) external view returns (uint256);
  function maximumSupply(uint256 groupId) external view returns (uint256);
  function mintToken(address account, uint256 groupId, uint256 count, uint256 seed) external;
  function balanceOf(address owner) external view returns (uint256);
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
  function ownerOf(uint256 tokenId) external view returns (address);
}

