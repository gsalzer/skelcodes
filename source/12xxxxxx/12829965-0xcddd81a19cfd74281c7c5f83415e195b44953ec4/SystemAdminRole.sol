/*
* SPDX-License-Identifier: UNLICENSED
* Copyright © 2021 Blocksquare d.o.o.
*/

pragma solidity ^0.6.12;

import "./SystemOwnerRole.sol";

/// @title System Admin Role
contract SystemAdminRole is SystemOwnerRole {
    bytes32 public constant SYSTEM_ADMIN_ROLE = keccak256("SYSTEM_ADMIN_ROLE");
    bytes32 public constant SYSTEM_OWNER_ROLE = keccak256("SYSTEM_OWNER_ROLE");

    constructor() internal {
        _setupRole(SYSTEM_OWNER_ROLE, _msgSender());
        _setupRole(SYSTEM_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(SYSTEM_ADMIN_ROLE, SYSTEM_OWNER_ROLE);
    }

    /// @notice checks if account has system admin role
    /// @param account Address to check
    /// @return true if account has system admin role otherwise false
    function isSystemAdmin(address account) public view returns (bool) {
        return hasRole(SYSTEM_ADMIN_ROLE, account);
    }

    /// @notice check if addr has system admin role or is system owner
    /// @param addr Address to check
    /// @return true if addr has system admin role or is system owner otherwise false
    function hasSystemAdminRights(address addr) public view returns (bool) {
        return isSystemOwnerAddress(addr) || hasRole(SYSTEM_ADMIN_ROLE, addr);
    }
}

