/*
* SPDX-License-Identifier: UNLICENSED
* Copyright © 2021 Blocksquare d.o.o.
*/

pragma solidity ^0.6.12;

import "./Ownable.sol";

import "./AccessControl.sol";

/// @title System Owner Role
contract SystemOwnerRole is Ownable, AccessControl {

    /// @notice checks if addr is owner of this system
    /// @param addr Address for checking
    /// @return true if addr is owner otherwise false
    function isSystemOwnerAddress(address addr) public view returns (bool) {
        return addr == owner();
    }

    /// @notice checks if caller is owner of this system
    /// @return true if caller is owner otherwise false
    function isSystemOwner() public view returns (bool) {
        return isSystemOwnerAddress(msg.sender);
    }
}

