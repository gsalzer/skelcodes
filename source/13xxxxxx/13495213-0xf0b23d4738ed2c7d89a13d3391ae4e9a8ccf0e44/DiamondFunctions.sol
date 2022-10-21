// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Functions {
    
  function addToWhitelist(address[] calldata addresses) external;

  function onWhitelist(address addr) external returns (bool);

  function removeFromWhitelist(address[] calldata addresses) external;
  
  function WhitelistClaimedBy(address owner) external returns (uint256);
  
  function addToFirestarter1(address[] calldata addresses) external;

  function onFirestarter1(address addr) external returns (bool);

  function removeFromFirestarter1(address[] calldata addresses) external;
  
  function Firestarter1ClaimedBy(address owner) external returns (uint256);
  
  function addToFirestarter2(address[] calldata addresses) external;

  function onFirestarter2(address addr) external returns (bool);

  function removeFromFirestarter2(address[] calldata addresses) external;
  
  function Firestarter2ClaimedBy(address owner) external returns (uint256);
  
  function addToPresale(address[] calldata addresses) external;

  function onPresale(address addr) external returns (bool);

  function removeFromPresale(address[] calldata addresses) external;
  
  function PresaleClaimedBy(address owner) external returns (uint256);

  function mintpresale(uint256 numberOfTokens) external payable;
  
  function mintwhitelist(uint256 numberOfTokens) external payable;
  
  function mintfirestarter1(uint256 numberOfTokens) external payable;
  
  function mintfirestarter2(uint256 numberOfTokens) external payable;
  
  function mintpublic(uint256 numberOfTokens) external payable;

  function mintadambombsquad(uint256 numberOfTokens) external payable;

  function MasterActive(bool isMasterActive) external;
  
  function PublicActive(bool isPublicActive) external;
  
  function BombSquadActive(bool isBombSquadActive) external;
  
  function WhitelistActive(bool isWhitelistActive) external;
  
  function PresaleActive(bool isPresaleActive) external;
  
  function FirestarterActive(bool _isFirestarterActive) external;

  function airdrop(address[] calldata to) external;

  function reserve(address[] calldata to) external;

  function withdraw() external;
  
}
