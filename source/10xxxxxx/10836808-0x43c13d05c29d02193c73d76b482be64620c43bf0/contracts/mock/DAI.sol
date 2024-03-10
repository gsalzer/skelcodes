// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import { TestToken } from "./TestToken.sol";

contract DAI is TestToken {
  constructor() TestToken("DAI", "DAI", 18) public {}
}

