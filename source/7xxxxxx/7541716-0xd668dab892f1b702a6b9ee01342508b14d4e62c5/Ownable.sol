/**
Copyright (c) 2014-2552 AnthemGold INC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

pragma solidity ^0.5.0;

/**
 * @title Ownable
 */
contract Ownable {

  // Owner of the contract
  address private _owner;

  /**
  * @dev Event to show ownership has been transferred
  * @param previousOwner representing the address of the previous owner
  * @param newOwner representing the address of the new owner
  */
  event OwnershipTransferred(address previousOwner, address newOwner);

  /**
  * @dev The constructor sets the original owner of the contract to the sender account.
  */
  constructor() public {
    setOwner(msg.sender);
  }

  /**
 * @dev Tells the address of the owner
 * @return the address of the owner
 */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Sets a new owner address
   */
  function setOwner(address newOwner) internal {
    _owner = newOwner;
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyOwner() {
    require(msg.sender == owner());
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner(), newOwner);
    setOwner(newOwner);
  }
}

