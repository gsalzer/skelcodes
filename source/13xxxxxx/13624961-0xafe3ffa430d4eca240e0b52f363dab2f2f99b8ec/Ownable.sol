// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public admin;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    admin = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == admin);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newAdmin The address to transfer ownership to.
   */
  function transferOwnership(address newAdmin) external onlyOwner {
    require(newAdmin != address(0));
    emit OwnershipTransferred(admin, newAdmin);
    admin = newAdmin;
  }
}

