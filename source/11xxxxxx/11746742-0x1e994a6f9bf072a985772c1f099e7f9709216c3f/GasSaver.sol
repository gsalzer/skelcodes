// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import './ChiToken.sol';

abstract contract GasSaver {
    constructor() public {
        ChiToken(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c).approve(address(this), 2**256 - 1);
    }

    modifier discountCHI {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        ChiToken(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c).freeFromUpTo(msg.sender, (gasSpent + 14154) / 41130);
    }
}
