// SPDX-License-Identifier: Unlicense
pragma solidity >=0.4.26;

interface IGatherToken {
  function unpauseTransfer() external;
  function pauseTransfer() external;
  function transferPaused() external returns (bool);

  function owner() external returns (address);
  function transferOwnership(address newOwner) external;

  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
}
