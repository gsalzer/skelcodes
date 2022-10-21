pragma solidity ^0.4.23;

import "./RBAC.sol";


/**
 * @title RBACWithAdmin
 * @author Matt Condon (@Shrugs)
 * @ It's recommended that you define constants in the contract,
 * @ like ROLE_ADMIN below, to avoid typos.
 */
contract RBACWithAdmin is RBAC {
  /**
   * A constant role name for indicating admins.
   */
  string public constant ROLE_ADMIN = "admin";

  /**
   *  modifier to scope access to admins
   * // reverts
   */
  modifier onlyAdmin()
  {
    checkRole(msg.sender, ROLE_ADMIN);
    _;
  }

  /**
   *  constructor. Sets msg.sender as admin by default
   */
  constructor()
    public
  {
    addRole(msg.sender, ROLE_ADMIN);
  }

  /**
   *  add a role to an address
   * @param addr address
   * @param roleName the name of the role
   */
  function adminAddRole(address addr, string roleName)
    onlyAdmin
    public
  {
    addRole(addr, roleName);
  }

  /**
   *  remove a role from an address
   * @param addr address
   * @param roleName the name of the role
   */
  function adminRemoveRole(address addr, string roleName)
    onlyAdmin
    public
  {
    removeRole(addr, roleName);
  }
}

