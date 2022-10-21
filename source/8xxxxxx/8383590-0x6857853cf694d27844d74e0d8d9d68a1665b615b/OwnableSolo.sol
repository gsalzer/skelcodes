pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract OwnableSolo {
  
  //@dev stores the wallet address of the owner of the contract
  address public owner;
  
  //@dev stores the wallet address to allow token creation
  address[] public accounts;

  //@dev keeps track if a function is paused or not, only owner of the contract can change this value to true.
  bool public paused = false;
  
  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  //@dev throws if "paused" set to true.
  modifier ifNotPaused() {
        require(!paused);
        _;
    }

  //@dev sets the paused variable to false.
  function unpause() public onlyOwner {
        paused = false;
  }
   
  //@dev set the paused varible to true.
  function pause() public onlyOwner{
        paused = true;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  //@dev Throws if called by any account other than the owners wallet address.
  modifier onlyCreator(){
    for (uint i = 0; i < accounts.length; i++){
     if(accounts[i] == msg.sender){
      _;
      return;
     }
    }
    revert();
  }

  //@dev sets a wallet address to be able to create marbles, only the owner of the contract can set a creator
  //@param _newcreator takes the wallet address of a new creator
  function setCreator(address _newcreator) public onlyOwner {
    accounts.push(_newcreator);
  }
  

  //@dev clears the array of all accounts stored
  function deleteCreators() public onlyOwner{
    delete accounts;
  }


  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

//The MIT License (MIT)

// Copyright (c) 2016 Smart Contract Solutions, Inc.

// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:

// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// © 2018 GitHub, Inc.
