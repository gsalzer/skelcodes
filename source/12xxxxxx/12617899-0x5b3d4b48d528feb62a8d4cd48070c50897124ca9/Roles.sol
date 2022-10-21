pragma solidity ^0.4.23;


/**
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 *      See RBAC.sol for example usage.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   *  give an address access to this role
   */
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

  /**
   *  remove an address' access to this role
   */
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

  /**
   *  check if an address has this role
   * // reverts
   */
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

  /**
   *  check if an address has this role
   * @return bool
   */
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}

