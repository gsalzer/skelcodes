// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @dev A basic interface for ENS resolvers.
 */
interface IResolver {
    function supportsInterface(bytes4 interfaceID) external pure returns (bool);
    function addr(bytes32 node) external view returns (address);
    function setAddr(bytes32 node, address _addr) external;
}

