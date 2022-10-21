//SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IRandomNumberGenerator {
    /**
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber()
        external
        returns (bytes32 requestId);
}

