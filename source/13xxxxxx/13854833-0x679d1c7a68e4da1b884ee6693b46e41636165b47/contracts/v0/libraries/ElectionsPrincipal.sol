// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

/**
 * This interface gives readonly access to ToonToken contract's data
 * needed by the `Elections` library
 */
interface ElectionsPrincipal {
    /**
     * Returns the address of a candidate a tokenholder account left its
     * votes for. In case of `address(0)` a voter is treated as an abstained.
     */
    function candidateOf(address account) external view returns (address);

    /**
     * Returns the number of votes the `account` has.
     */
    function votesOf(address account) external view returns (uint256);
}

