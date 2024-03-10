// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IOreClaim {
  function lastClaimedWeekByTokenId(uint256 _tokenId) external view returns (uint256);
  function initialClaimTimestampByGroupId(uint256 _groupId) external view returns (uint256);
  function finalClaimTimestamp() external view returns (uint256);
}

