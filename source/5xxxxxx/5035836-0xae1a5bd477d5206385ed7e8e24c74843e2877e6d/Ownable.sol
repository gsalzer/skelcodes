pragma solidity ^0.4.18;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */

contract Ownable {
  address public owner;
  address public scriptAddress;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
    scriptAddress = address(0);
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Throws if called by any account other than the owner or script runner.
   */
  modifier onlyOwnerOrScript() {
    require(msg.sender == owner || msg.sender == scriptAddress);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to transfer script control of the contract to a newScriptAddress.
   * @param newScriptAddress The address to transfer script ownership to.
   */
  function setScriptAddress(address newScriptAddress) public onlyOwner {
    scriptAddress = newScriptAddress;
  }
}

