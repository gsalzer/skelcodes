//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental SMTChecker;

import "MToken.sol";

/// @title MBTC
contract MBTC is MToken {
    constructor() MToken("Matrix BTC Token", "MBTC", 8, (ERC20ControllerViewIf)(0)){}
}

