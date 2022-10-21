// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IContractFusion {
    function fuseTokens(address sender, uint toFuse, uint toBurn, bytes calldata payload) external;
}
