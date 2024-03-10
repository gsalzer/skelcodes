pragma solidity ^0.4.24;

import './Ownable.sol';

contract Administratable is Ownable {
  mapping (address => bool) admins;

  modifier onlyAdmin() {
    require(msg.sender == owner || admins[msg.sender]);
    _;
  }
  
  function addAdmin(address _adminAddr) onlyAdmin public returns (bool success) {
    admins[_adminAddr] = true;
    emit AdminAdded(_adminAddr, msg.sender);
    return true;
  }

  function revokeAdmin(address _adminAddr) onlyAdmin public returns (bool success) {
    require(msg.sender != _adminAddr);
    admins[_adminAddr] = false;
    emit AdminRevoked(_adminAddr, msg.sender);
    return true;
  }
  
  event AdminAdded(address indexed _admin, address indexed _by);
  event AdminRevoked(address indexed _admin, address indexed _by);
}

