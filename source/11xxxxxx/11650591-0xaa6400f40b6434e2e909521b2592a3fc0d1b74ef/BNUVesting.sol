pragma solidity ^0.7.1;

import "./SafeMath.sol";
import './BaseBNUStoreClient.sol';

/**
* @title Contract to store locked BNU tokens
* @dev Process to initialize locked tokens of accounts and times to be unlocked
*/
contract BNUVesting is BaseBNUStoreClient{
    using SafeMath for uint;

    uint public _startTime;

    address public _teamAddress;
    address public _advisorAddress;

    struct LockedToken {
        address account;
        uint amount;
        uint unlockedTime;
        bool unlocked;
    }

    /**
    * @dev Stores all locked tokens
    */
    LockedToken[] internal _lockedTokens;

    constructor(){
        _teamAddress = 0x830db936ad911D545388F2Bf736C9d05a9eA6753;
        _advisorAddress = 0xB2eB9c15bC077813736B36b7a00287c43dd9d732;
        
        _startTime = 1610518359;

        //Add locked histories
        _addLockedToken(_teamAddress, 30000000000000000000000000, 730 days);
        _addLockedToken(_advisorAddress, 16500000000000000000000000, 365 days);
    }

    /**
    * @dev Release locked token
     */
    function release() external onlyOwner contractActive returns(bool){
        return _release();
    }

    /** INTERNAL METHODS */

    /**
    * @dev Add locked token history 
    */
    function _addLockedToken(address account, uint amount, uint unlockedAfter) internal {
        _lockedTokens.push(LockedToken({
            account: account,
            amount: amount,
            unlockedTime: _startTime.add(unlockedAfter),
            unlocked: false
        }));
    }

    /**
    * @dev  Calculate to release unlocked token
    * 
    * Implementations:
    *   1. Get current time
    *   2. Get all locked histories that has not been unlocked and unlocked time less than current time
    *   3. Foreach validated histories, transfer tokens to beneficiary and update histories to unlocked
    */
    function _release() internal returns(bool){
        require(_startTime > 0, "Start time has not been initialized");
        bool isSuccess = false;
        uint currentTime = _now();
        if(_lockedTokens.length > 0){
            for(uint index = 0; index < _lockedTokens.length; index++){
               LockedToken storage lockedToken = _lockedTokens[index];
               if(!lockedToken.unlocked){
                   if(lockedToken.unlockedTime <= currentTime){
                       lockedToken.unlocked = true;
                       require(_bnuStoreContract.transfer(lockedToken.account, lockedToken.amount), "BNUVesting: Can not transfer token");
                       emit TokenReleased(lockedToken.account, lockedToken.amount, currentTime);
                       isSuccess = true;
                   }
               }
            }
        }
        
        return isSuccess;
    }

    /** EVENTS */
    /**
    * @dev Event to notify `amount` of token of `account` has been released at `time` 
    */
    event TokenReleased(address account, uint amount, uint time);
}

//SPDX-License-Identifier: MIT
