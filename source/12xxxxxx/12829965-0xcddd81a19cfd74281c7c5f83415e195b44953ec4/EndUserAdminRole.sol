/*
* SPDX-License-Identifier: UNLICENSED
* Copyright © 2021 Blocksquare d.o.o.
*/

pragma solidity ^0.6.12;

import "./CPAdminRole.sol";

/// @title End User Admin Role
contract EndUserAdminRole is CPAdminRole {
    bytes32 public constant END_USER_ADMIN_ROLE = keccak256("END_USER_ADMIN_ROLE");


    constructor() internal {
        _setRoleAdmin(END_USER_ADMIN_ROLE, SYSTEM_ADMIN_ROLE);
    }

    /// @notice Check if addr has end user admin role or has system admin rights
    /// @param addr Address to check
    /// @return true if addr has end user admin role or has system admin rights otherwise false
    function hasEndUserAdminRights(address addr) public view returns (bool) {
        return hasSystemAdminRights(addr) || hasRole(END_USER_ADMIN_ROLE, addr);
    }
}

