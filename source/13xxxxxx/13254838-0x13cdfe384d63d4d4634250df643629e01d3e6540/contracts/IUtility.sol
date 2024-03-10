/* SPDX-License-Identifier: BUSL-1.1 */
/* Copyright © 2021 Fragcolor Pte. Ltd. */

pragma solidity ^0.8.7;

interface IUtility {
    function overrideOwner() external pure returns (bool);

    function buildFragmentMetadata(
        uint160 hashId,
        bytes32 mutableHash,
        uint256 includeCost,
        uint256 immutableBlock,
        uint256 mutableBlock
    ) external view returns (string memory metadata);

    function buildFragmentRootMetadata(
        address vaultAddress,
        uint256 feeBasisPoints
    ) external pure returns (string memory metadata);

    function buildEntityMetadata(
        uint256 id,
        bytes32 mutableHash,
        address entityId,
        uint256 dataBlock
    ) external view returns (string memory metadata);

    function buildEntityRootMetadata(
        string memory name,
        string memory desc,
        string memory url,
        address vaultAddress,
        uint256 feeBasisPoints
    ) external pure returns (string memory metadata);

    function getRezProxyBytecode()
        external
        pure
        returns (bytes memory bytecode);
}

