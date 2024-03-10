// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";

contract MinterRole is AccessControl {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  constructor(address[] memory minters) {
    // give owner DEFAULT_ADMIN_ROLE to be able to adjust permissions
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

    for(uint i = 0; i < minters.length; i++) {
      _grantRole(MINTER_ROLE, minters[i]);
    }
  }
}

