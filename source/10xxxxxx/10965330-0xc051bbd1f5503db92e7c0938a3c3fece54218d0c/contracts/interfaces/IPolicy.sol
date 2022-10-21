// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import { FauxblocksLib } from "../FauxblocksLib.sol";

interface IPolicy {
  function acceptTransaction(address sender, FauxblocksLib.Transaction memory trx) external view returns (FauxblocksLib.TransactionType code, bytes memory);
}

