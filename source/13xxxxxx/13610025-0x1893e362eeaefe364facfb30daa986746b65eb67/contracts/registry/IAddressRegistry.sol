// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

interface IAddressRegistry {
    function getIds() external view returns (bytes32[] memory);

    function getAddress(bytes32 id) external view returns (address);
}

