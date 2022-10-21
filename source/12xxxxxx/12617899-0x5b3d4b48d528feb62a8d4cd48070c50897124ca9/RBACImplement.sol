pragma solidity ^0.4.23;

import "./RBACWithAdmin.sol";


contract RBACImplement is RBACWithAdmin {

  string public constant ROLE_ADVISOR = "advisor";

  modifier onlyAdminOrAdvisor()
  {
    require(
      hasRole(msg.sender, ROLE_ADMIN) ||
      hasRole(msg.sender, ROLE_ADVISOR)
    );
    _;
  }

  constructor()
    public
  {
    addRole(msg.sender, ROLE_ADVISOR);
  }

  // admins can remove advisor's role
  function removeAdvisor(address _addr)
    onlyAdmin
    public
  {
    // revert if the user isn't an advisor
    //  (perhaps you want to soft-fail here instead?)
    checkRole(_addr, ROLE_ADVISOR);

    // remove the advisor's role
    removeRole(_addr, ROLE_ADVISOR);
  }
}

