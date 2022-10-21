/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.6.8;

library BitmapLib {
    bytes32 constant internal empty = bytes32(0);

    function flip(bytes32 map, uint8 index) internal pure returns (bytes32) {
        return bytes32(uint256(map) ^ uint256(1) << index);
    }

    function get(bytes32 map, uint8 index) internal pure returns (bool) {
        return (uint256(map) >> index & 1) == 1;
    }
}

