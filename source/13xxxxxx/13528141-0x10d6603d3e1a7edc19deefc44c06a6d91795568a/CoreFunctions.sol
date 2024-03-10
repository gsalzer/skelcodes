// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Functions {
 
  function membershipClaimGenesis(uint256 membershipTokenID) external;

  function membershipClaim(uint256 membershipTokenID) external;

  function mintPublic(uint256 numberOfTokens) external payable;

  function mintMembership(uint256 numberOfTokens) external payable;

  function MasterActive(bool isMasterActive) external;

  function MembershipActive(bool isMembershipActive) external;

  function PassActive(bool isPassActive) external;

  function PublicActive(bool isPublicActive) external;

  function withdraw() external;
  
  function reserve(address[] calldata to) external;

}
