// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ITransportMinter {
    function allocatedTransports(uint256 tokenId) external view returns (address);
}

