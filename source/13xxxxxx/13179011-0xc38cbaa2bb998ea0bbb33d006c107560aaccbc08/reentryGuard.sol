// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.7;

contract Guarded {
    uint256 constant NOT_ENTERED = 1;
    uint256 constant ENTERED = 2;
    uint256 entryState = NOT_ENTERED;

    modifier guarded() {
        require(entryState == NOT_ENTERED, "Reentry");
        entryState = ENTERED;
        _;
        entryState = NOT_ENTERED;
    }
}

