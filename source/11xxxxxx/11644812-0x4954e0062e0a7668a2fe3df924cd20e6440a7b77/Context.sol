pragma solidity ^0.7.1;

/**
 * @title Context
 * @dev Provide context functions
 */
abstract contract Context {
    address public owner;            //Contract owner address
    bool public isContractActive;           //Make sure this contract can be used or not
    
    /**
     * Make sure the sender is the owner of contract
     */ 
    modifier onlyOwner{
        require(_msgSender() == owner, "Only owner can process");
        _;
    }
    
    /**
     * Make sure the contract is active to execute
    */ 
    modifier contractActive{
        require(isContractActive, "This contract is deactived");
        _;
    }

    /**
    * @dev Constructor
    * 
    * Implementations:
    *   1. Set the owner of contract
    *   2. Set contract is active
    */
    constructor(){
       owner = _msgSender();           //Set owner address when contract is created
       isContractActive = true;        //Contract is active when it is created
    }

    /**
     * Get sender address
     */ 
    function _msgSender() internal view returns(address){
        return msg.sender;
    }

    /**
     * Get current time in unix timestamp
     */
    function _now() internal view returns(uint){
        return block.timestamp;
    }

    /**
    * Update contract status to make sure this contract can be executed or not
     */
    function setContractStatus(bool status) external onlyOwner{
        require(isContractActive != status,"The current contract's status is the same with updating status");
        isContractActive = status;
    }

    /**
    * @dev Change contract's owner
    * @return If success return true; else return false
    * 
    * Requirements:
    *   1. Only current owner can execute
    *   2. `newOwner` is not zero address
    *   3. `newOwner` is not current owner
    * 
    * Implementations:
    *   1. Validate requirements
    *   2. Set current owner is newOwner
    *   3. Emit Events
    *   4. Return result
    */
    function setOwner(address newOwner) external onlyOwner returns(bool){
        require(newOwner != address(0), "New owner is zero address");
        require(newOwner != owner, "New owner is current owner");

        owner = newOwner;

        emit OwnerChanged(owner);
        return true;
    }

    /**
    * @dev Event that notifies contract's owner has been changed to `newOwner` 
    */
    event OwnerChanged(address newOwner);
}

//SPDX-License-Identifier: MIT
