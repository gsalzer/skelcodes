// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IMintPass {
  function passExists(uint256 _passId) external view returns (bool);
  function passDetail(uint256 _tokenId) external view returns (address, uint256, uint256);
  function mintToken(
    address _account,
    uint256 _passId,
    uint256 _count
  ) external;
  function burnToken(uint256 _tokenId) external;
}

