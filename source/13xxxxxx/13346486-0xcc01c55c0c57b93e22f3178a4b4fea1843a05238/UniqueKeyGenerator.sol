// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract UniqueKeyGenerator {
    uint256 private salt;

    function generateKey(address a) internal view returns (bytes32) {
        return keccak256(abi.encode(uint256(uint160(a)) + salt));
    }

    function generateKey(uint256 u) internal view returns (bytes32) {
        return keccak256(abi.encode(u + salt));
    }

    // adds more salt -> makes duplicating keys near impossible
    function addSalt() internal {
        salt += 100000000;
    }
}
