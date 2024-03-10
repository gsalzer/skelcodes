// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IOre {
  function balanceOf(address owner) external view returns (uint256);
  function mint(address account, uint256 amount) external;
  function burn(address account, uint256 amount) external;
}

