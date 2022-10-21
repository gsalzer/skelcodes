pragma solidity ^0.5.8;

import "./Roles.sol";
import "./Ownable.sol";

contract Whitelist is Ownable {
  using Roles for Roles.Role;

  Roles.Role private whitelist;

  event WhitelistedAddressAdded(address indexed _address);

  function isWhitelisted(address _address) public view returns (bool) {
    return whitelist.has(_address);
  }

  function addAddressToWhitelist(address _address) external onlyOwner {
    _addAddressToWhitelist(_address);
  }

  function addAddressesToWhitelist(address[] calldata _addresses) external onlyOwner {
    for (uint i = 0; i < _addresses.length; i++) {
      _addAddressToWhitelist(_addresses[i]);
    }
  }

  function _addAddressToWhitelist(address _address) internal {
    whitelist.add(_address);
    emit WhitelistedAddressAdded(_address);
  }
}

