// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Functions {
 
  function mint(uint256 numberOfTokens) external payable;

  function MasterActive(bool isMasterActive) external;

  function withdraw() external;
  
  function reserve(address[] calldata to) external;

}
