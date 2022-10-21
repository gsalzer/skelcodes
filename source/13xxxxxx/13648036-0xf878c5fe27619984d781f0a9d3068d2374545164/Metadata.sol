// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Metadata {
  function setContractURI(string calldata URI) external;

  function setMetadataURI(string calldata revealedBaseURI) external;

  function contractURI() external view returns(string memory);
}
