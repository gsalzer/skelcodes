// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import { TestToken } from "./TestToken.sol";

contract WBTC is TestToken {
  constructor() TestToken("WBTC", "WBTC", 8) public {}
}

