// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INightWorldMetadata {
  function setContractURI(string calldata URI) external;

  function setBaseURI(string calldata URI) external;

  function setRevealedBaseURI(string calldata revealedBaseURI) external;

  function setTwiceRevealedBaseURI(string calldata twiceRevealedBaseURI) external;

  function setIntervalRevealedBaseURI(uint256 index, string calldata twiceRevealedBaseURI) external;

  function contractURI() external view returns(string memory);
}
