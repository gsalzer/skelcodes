// SPDX-License-Identifier: MIT
pragma solidity =0.7.5;

import "LibBaseAuth.sol";
import "LibAuthPause.sol";
import "LibAuthProxy.sol";


contract AuthVoken is BaseAuth, AuthPause, AuthProxy {
    using Roles for Roles.Role;

    Roles.Role private _banks;
    Roles.Role private _minters;

    event BankAdded(address indexed account);
    event BankRemoved(address indexed account);
    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);


    /**
     * @dev Throws if called by account which is not a minter.
     */
    modifier onlyMinter()
    {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
        _;
    }

    /**
     * @dev Returns true if the `account` has the Bank role.
     */
    function isBank(address account)
        public
        view
        returns (bool)
    {
        return _banks.has(account);
    }

    /**
     * @dev Give an `account` access to the Bank role.
     *
     * Can only be called by the current owner.
     */
    function addBank(address account)
        public
        onlyAgent
    {
        _banks.add(account);
        emit BankAdded(account);
    }

    /**
     * @dev Remove an `account` access from the Bank role.
     *
     * Can only be called by the current owner.
     */
    function removeBank(address account)
        public
        onlyAgent
    {
        _banks.remove(account);
        emit BankRemoved(account);
    }

    /**
     * @dev Returns true if the `account` has the Minter role
     */
    function isMinter(address account)
        public
        view
        returns (bool)
    {
        return _minters.has(account);
    }

    /**
     * @dev Give an `account` access to the Minter role.
     *
     * Can only be called by the current owner.
     */
    function addMinter(address account)
        public
        onlyAgent
    {
        _minters.add(account);
        emit MinterAdded(account);
    }

    /**
     * @dev Remove an `account` access from the Minter role.
     *
     * Can only be called by the current owner.
     */
    function removeMinter(address account)
        public
        onlyAgent
    {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}
