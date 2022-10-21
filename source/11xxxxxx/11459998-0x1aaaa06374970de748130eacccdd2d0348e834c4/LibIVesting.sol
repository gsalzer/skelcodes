// SPDX-License-Identifier: MIT
pragma solidity =0.7.5;


/**
 * @dev Interface of an vesting contract.
 */
interface IVesting {
    function vestingOf(address account) external view returns (uint256);
}

