// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Functions {
  function addToCollection1(address[] calldata addresses) external;

  function onCollection1(address addr) external returns (bool);

  function removeFromCollection1(address[] calldata addresses) external;

  function addToCollection2(address[] calldata addresses) external;

  function onCollection2(address addr) external returns (bool);

  function removeFromCollection2(address[] calldata addresses) external;

  function addToCollection3(address[] calldata addresses) external;

  function onCollection3(address addr) external returns (bool);

  function removeFromCollection3(address[] calldata addresses) external;

  function Collection1ClaimedBy(address owner) external returns (uint256);

  function Collection2ClaimedBy(address owner) external returns (uint256);

  function Collection3ClaimedBy(address owner) external returns (uint256);

  function mintCollection1(uint256 numberOfTokens) external payable;

  function mintCollection2(uint256 numberOfTokens) external payable;

  function mintCollection3(uint256 numberOfTokens) external payable;

  function MasterActive(bool isMasterActive) external;

  function Collection1Active(bool isCollection1Active) external;

  function Collection2Active(bool isCollection2Active) external;

  function Collection3Active(bool isCollection3Active) external;

  function setMessage(string memory messageString) external;

  function withdraw() external;
}
