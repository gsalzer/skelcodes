// SPDX-License-Identifier: MIT
pragma solidity =0.7.5;

import "LibBaseAuth.sol";


/**
 * @dev Auth proxy.
 */
contract AuthProxy is BaseAuth {
    using Roles for Roles.Role;

    Roles.Role private _proxies;
    
    event ProxyAdded(address indexed account);
    event ProxyRemoved(address indexed account);


    /**
     * @dev Throws if called by account which is not a proxy.
     */
    modifier onlyProxy() {
        require(isProxy(msg.sender), "ProxyRole: caller does not have the Proxy role");
        _;
    }

    /**
     * @dev Returns true if the `account` has the Proxy role.
     */
    function isProxy(address account)
        public
        view
        returns (bool)
    {
        return _proxies.has(account);
    }

    /**
     * @dev Give an `account` access to the Proxy role.
     *
     * Can only be called by the current owner.
     */
    function addProxy(address account)
        public
        onlyAgent
    {
        _proxies.add(account);
        emit ProxyAdded(account);
    }

    /**
     * @dev Remove an `account` access from the Proxy role.
     *
     * Can only be called by the current owner.
     */
    function removeProxy(address account)
        public
        onlyAgent
    {
        _proxies.remove(account);
        emit ProxyRemoved(account);
    }
}

