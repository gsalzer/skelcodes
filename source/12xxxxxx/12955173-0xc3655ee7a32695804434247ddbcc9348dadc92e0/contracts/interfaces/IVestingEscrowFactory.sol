// SPDX-License-Identifier: ISC
pragma solidity 0.7.6;

import { IStakedLyra } from "./IStakedLyra.sol";

interface IVestingEscrowFactory {
  function stakedToken() external view returns (IStakedLyra);

  function deploymentTimestamp() external view returns (uint256);
}

