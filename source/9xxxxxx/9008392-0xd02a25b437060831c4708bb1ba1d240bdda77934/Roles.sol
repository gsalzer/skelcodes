pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an address access to this role
     */
    function add(Role storage _role, address _addr)
        internal
    {
        require(!has(_role, _addr), "Roles: addr already has role");
        _role.bearer[_addr] = true;
    }

    /**
     * @dev remove an address' access to this role
     */
    function remove(Role storage _role, address _addr)
        internal
    {
        require(has(_role, _addr), "Roles: addr do not have role");
        _role.bearer[_addr] = false;
    }

    /**
     * @dev check if an address has this role
     * // reverts
     */
    function check(Role storage _role, address _addr)
        internal
        view
    {
        require(has(_role, _addr),'Roles: addr do not have role');
    }

    /**
     * @dev check if an address has this role
     * @return bool
     */
    function has(Role storage _role, address _addr)
        internal
        view
        returns (bool)
    {
        require(_addr != address(0), "Roles: not the zero address");
        return _role.bearer[_addr];
    }
}

