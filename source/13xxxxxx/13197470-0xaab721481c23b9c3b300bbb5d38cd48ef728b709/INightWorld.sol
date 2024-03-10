// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INightWorld {

  event Twice(address indexed owner, uint256 indexed tokenId);

  function addToAllowList(address[] calldata addresses) external;

  function onAllowList(address addr) external returns (bool);

  function onTwiceList(uint256 tokenId) external returns (bool);

  function onBenefitList(uint256 tokenId) external returns (bool);

  function removeFromAllowList(address[] calldata addresses) external;

  function allowListClaimedBy(address owner) external returns (uint256);

  function purchase(uint256 numberOfTokens) external payable;

  function purchaseTwice(uint256 tokenId) external payable;

  function purchaseAllowList(uint256 numberOfTokens) external payable;

  function gift(address[] calldata to) external;

  function benefit(uint256 _tokenId) external;

  function mintReserved(uint256 numberOfTokens) external;

  function setIsActive(bool isActive) external;

  function setIsTwiceActive(bool isActive) external;

  function setIsAllowListActive(bool isAllowListActive) external;

  function setAllowListMaxMint(uint256 maxMint) external;

  function setIsBenefitActive(bool _isBenefitActive, address _contractAddr) external;

  function withdraw() external;
}
