pragma solidity ^0.4.24;

/**
 * Library to support managing and checking per-address privileges.
 */
contract Privileged {
  mapping (address => uint8) public privileges;
  uint8 internal rootPrivilege;

  constructor(uint8 _rootPrivilege) internal {
    rootPrivilege = _rootPrivilege;
    privileges[msg.sender] = rootPrivilege;
  }

  function grantPrivileges(address _target, uint8 _privileges) public requirePrivileges(rootPrivilege) {
    privileges[_target] |= _privileges;
  }

  function removePrivileges(address _target, uint8 _privileges) public requirePrivileges(rootPrivilege) {
    // May not remove privileges from self.
    require(_target != msg.sender);
    privileges[_target] &= ~_privileges;
  }

  modifier requirePrivileges(uint8 _mask) {
    require((privileges[msg.sender] & _mask) == _mask);
    _;
  }
}

