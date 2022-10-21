pragma solidity ^0.5.2;

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));
        role.bearer[account] = true;
    }

    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));
        role.bearer[account] = false;
    }

    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}
