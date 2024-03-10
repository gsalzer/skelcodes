// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IMakerPriceFeed {
  function read() external view returns (bytes32);
}
