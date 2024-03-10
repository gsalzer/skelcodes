// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Functions {
  function addToTier1(address[] calldata addresses) external;

  function onTier1(address addr) external returns (bool);

  function removeFromTier1(address[] calldata addresses) external;
  
  function addToTier2(address[] calldata addresses) external;

  function onTier2(address addr) external returns (bool);

  function removeFromTier2(address[] calldata addresses) external;

  function addToTier3(address[] calldata addresses) external;

  function onTier3(address addr) external returns (bool);

  function removeFromTier3(address[] calldata addresses) external;

  function addToTier4(address[] calldata addresses) external;

  function onTier4(address addr) external returns (bool);

  function removeFromTier4(address[] calldata addresses) external;
  
  function addToTier5(address[] calldata addresses) external;

  function onTier5(address addr) external returns (bool);

  function removeFromTier5(address[] calldata addresses) external;
  
  function addToTier6(address[] calldata addresses) external;

  function onTier6(address addr) external returns (bool);

  function removeFromTier6(address[] calldata addresses) external;
  
  function Tier1ClaimedBy(address owner) external returns (uint256);
  
  function Tier2ClaimedBy(address owner) external returns (uint256);

  function Tier3ClaimedBy(address owner) external returns (uint256);

  function Tier4ClaimedBy(address owner) external returns (uint256);

  function Tier5ClaimedBy(address owner) external returns (uint256);

  function Tier6ClaimedBy(address owner) external returns (uint256);

  function mintTier1(uint256 numberOfTokens) external payable;

  function mintTier2(uint256 numberOfTokens) external payable;

  function mintTier3(uint256 numberOfTokens) external payable;

  function mintTier4(uint256 numberOfTokens) external payable;

  function mintTier5(uint256 numberOfTokens) external payable;

  function mintTier6(uint256 numberOfTokens) external payable;

  function mintPublic(uint256 numberOfTokens) external payable;

  function reserve(address[] calldata to) external;

  function MasterActive(bool isMasterActive) external;
  
  function PublicActive(bool isPublicActive) external;

  function Tier1Active(bool isTier1Active) external;

  function Tier2Active(bool isTier2Active) external;

  function Tier3Active(bool isTier3Active) external;

  function Tier4Active(bool isTier4Active) external;

  function Tier5Active(bool isTier5Active) external;

  function Tier6Active(bool isTier6Active) external;

  function setMessage(string memory messageString) external;

  function withdraw() external;
}
