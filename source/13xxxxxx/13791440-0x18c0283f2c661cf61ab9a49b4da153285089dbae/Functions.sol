// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Functions {

  function addToWhitelist(address[] calldata addresses) external;

  function onWhitelist(address addr) external returns (bool);

  function removeFromWhitelist(address[] calldata addresses) external;

  function WhitelistClaimedBy(address owner) external returns (uint256);

  function mintWhitelist(uint256 numberOfTokens) external payable;

  function mintPublic(uint256 numberOfTokens) external payable;

  function reserve(address[] calldata to) external;

  function MasterActive(bool isMasterActive) external;
  
  function WhitelistActive(bool isWhitelistActive) external;

  function PublicActive(bool isPublicActive) external;

  function setMessage(string memory messageString) external;

  function withdraw() external;
}
