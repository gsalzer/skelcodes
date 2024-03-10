// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Lockable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Locked(address account, address target);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event UnLocked(address account, address target);

    mapping(address => bool) public frozenList;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
    }

    /**
     * @dev Returns true if the address is frozen, and false otherwise.
     */
    function locked(address checkaddress) public view virtual returns (bool) {
        return frozenList[checkaddress];
    }

    /**
     * @dev Triggers locked state.
     *
     * Requirements:
     *
     * - The address must not be locked.
     */
    function _lock(address targetAddress) internal virtual {
        require(frozenList[targetAddress] != true, "ACCOUNT HAS ALREADY BEEN LOCKED.");
        frozenList[targetAddress] = true;
        emit Locked(_msgSender(), targetAddress);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The address must be locked.
     */
    function _unlock(address targetAddress) internal virtual {
        require(frozenList[targetAddress] != false, "ACCOUNT HAS NOT BEEN LOCKED.");
        frozenList[targetAddress] = false;
        emit UnLocked(_msgSender(), targetAddress);
    }
}

