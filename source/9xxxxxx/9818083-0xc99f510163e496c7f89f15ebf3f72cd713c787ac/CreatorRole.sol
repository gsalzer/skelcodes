pragma solidity ^0.6.1;

import "./Roles.sol";

contract CreatorRole {
  using Roles for Roles.Role;

  event CreatorAdded(address indexed account);
  event CreatorRemoved(address indexed account);

  Roles.Role private _creators;

  constructor () internal {
    _addCreator(msg.sender);
  }

  modifier onlyCreator() {
    require(isCreator(msg.sender), "CreatorRole: caller does not have the Creator role");
    _;
  }

  function isCreator(address account) public view returns (bool) {
    return _creators.has(account);
  }

  function addCreator(address account) public onlyCreator {
    _addCreator(account);
  }

  function renounceCreator() public {
    _removeCreator(msg.sender);
  }

  function _addCreator(address account) internal {
    _creators.add(account);
    emit CreatorAdded(account);
  }

  function _removeCreator(address account) internal {
    _creators.remove(account);
    emit CreatorRemoved(account);
  }
}

