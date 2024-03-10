pragma solidity ^0.5.8;

import "./Roles.sol";

contract PriceManagerRole {
  using Roles for Roles.Role;

  event PriceManagerAdded(address indexed account);
  event PriceManagerRemoved(address indexed account);

  Roles.Role private managers;

  constructor() internal {
    _addPriceManager(msg.sender);
  }

  modifier onlyPriceManager() {
    require(isPriceManager(msg.sender), "Only for price manager");
    _;
  }

  function isPriceManager(address account) public view returns (bool) {
    return managers.has(account);
  }

  function addPriceManager(address account) public onlyPriceManager {
    _addPriceManager(account);
  }

  function renouncePriceManager() public {
    _removePriceManager(msg.sender);
  }

  function _addPriceManager(address account) internal {
    managers.add(account);
    emit PriceManagerAdded(account);
  }

  function _removePriceManager(address account) internal {
    managers.remove(account);
    emit PriceManagerRemoved(account);
  }
}

