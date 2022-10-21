/*
* SPDX-License-Identifier: UNLICENSED
* Copyright © 2021 Blocksquare d.o.o.
*/

pragma solidity ^0.6.12;

import "./SystemAdminRole.sol";

/// @title Certified Partner Admin Role
contract CPAdminRole is SystemAdminRole {
    bytes32 public constant CP_ADMIN_ROLE = keccak256("CP_ADMIN_ROLE");

    mapping(address => mapping(bytes32 => bool)) private _forCP;

    constructor () internal {
        _setRoleAdmin(CP_ADMIN_ROLE, SYSTEM_ADMIN_ROLE);
    }


    /// @notice checks if account is admin of cp
    /// @param account Address of admin
    /// @param cp Certified Partner identifier
    /// @return true if account is admin of cp otherwise false
    function isCPAdminOf(address account, string memory cp) public view returns (bool) {
        bytes32 cpBytes = getUserBytes(cp);
        return hasSystemAdminRights(account) || (_forCP[account][cpBytes] && hasRole(CP_ADMIN_ROLE, account));
    }

    /// @notice checks if account is admin of cpBytes
    /// @param account Address of admin
    /// @param cpBytes Hashed Certified Partner identifier
    /// @return true if account is admin of cpBytes otherwise false
    function isCPAdminOf(address account, bytes32 cpBytes) public view returns (bool) {
        return hasSystemAdminRights(account) || (_forCP[account][cpBytes] && hasRole(CP_ADMIN_ROLE, account));
    }

    /// @notice make account admin of cp
    /// @param account Address of admin
    /// @param cp Certified Partner identifier
    function addCPAdmin(address account, string memory cp) public {
        require(hasSystemAdminRights(msg.sender), "CPAdminRole: You need to have system admin rights!");
        grantRole(CP_ADMIN_ROLE, account);
        bytes32 cpBytes = getUserBytes(cp);
        _forCP[account][cpBytes] = true;
    }

    /// @notice checks if addr has Certified Partner admin role or has system admin rights
    /// @param addr Address to check
    /// @return true if addr Certified Partner admin role or has system admin rights otherwise false
    function hasCPAdminRights(address addr) public view returns (bool) {
        return hasSystemAdminRights(addr) || hasRole(CP_ADMIN_ROLE, addr);
    }

    /// @notice get keccak256 hash of string
    /// @param user User or Certified Partner identifier
    /// @return keccak256 hash
    function getUserBytes(string memory user) public view returns (bytes32) {
        return keccak256(abi.encode(user));
    }
}

