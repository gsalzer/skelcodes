pragma solidity 0.5.12;

import './Roles.sol';
import './Pausable.sol';

contract AdminRole is Pausable {
  using Roles for Roles.Role;

  event AdminAdded(address indexed account);
  event AdminRemoved(address indexed account);

  Roles.Role private _admins;

  modifier onlyAdmin() {
    require(
      isAdmin(_msgSender()),
      'AdminRole: caller does not have the Admin role'
    );
    _;
  }

  function isAdmin(address account) public view returns (bool) {
    return _admins.has(account);
  }

  // adding an admin should be possible any time
  function addAdmin(address account) external onlyOwner {
    _addAdmin(account);
  }

  // removing an admin should be possible any time
  function removeAdmin(address account) external onlyOwner {
    _removeAdmin(account);
  }

  // renouncing admin role should be possible any time
  function renounceAdmin() external {
    _removeAdmin(_msgSender());
  }

  function _addAdmin(address account) internal {
    _admins.add(account);
    emit AdminAdded(account);
  }

  function _removeAdmin(address account) internal {
    _admins.remove(account);
    emit AdminRemoved(account);
  }

  uint256[50] private adminRoleGap;
}

