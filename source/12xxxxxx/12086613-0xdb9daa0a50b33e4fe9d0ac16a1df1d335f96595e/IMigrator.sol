// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface IMigrator {
    // Perform LP token migration from legacy LP token to new LP token.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to old LP tokens.
    // New LP tokens must mint EXACTLY the same amount of LP tokens or
    // else something bad will happen!!!
    function migrate(address token) external returns (address);
}

