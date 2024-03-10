// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

abstract contract Creator {
    function _calculateAddress(address creator, bytes32 salt, bytes32 hash) internal pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), creator, salt, hash)
        );
        return address(uint256(_data));
    }

    function _deploy(bytes32 salt, bytes memory bytecode) internal returns (address) {
        address addr;
        assembly {
            addr := create2(callvalue(), add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(addr) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        return addr;
    }
}

