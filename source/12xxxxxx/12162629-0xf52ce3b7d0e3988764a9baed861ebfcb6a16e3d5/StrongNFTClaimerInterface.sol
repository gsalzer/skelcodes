// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface StrongNFTClaimerInterface {
  function tokenNameAddressClaimed(string memory, address) external view returns(bool);
}

