pragma solidity ^0.7.1;

import './Context.sol';

/**
* @title Contract to process black list that can not transfer token
*/
abstract contract BlackList is Context{
    /**
    * @dev Mapping to check whether `address` is in blacklist or not
     */
    mapping (address => bool) internal _isBlackListed;

    /**
    * @dev Check whether `account` is in blacklist or not
    * @param account account to check
    * @return _isInBlackList internal function
    */
    function isInBlackList(address account) external view returns (bool) {
        return _isInBlackList(account);
    }
    
    /**
    * @dev Add new account to black list by marked is in black list as true 
    */
    function addToBlackList(address account) external onlyOwner {
        _isBlackListed[account] = true;
        emit AddedToBlackList(account);
    }

    /**
    * @dev Remove account from black list by marked is in black list as false 
    */
    function removeFromBlackList (address account) external onlyOwner {
        _isBlackListed[account] = false;
        emit RemovedFromBlackList(account);
    }

    /**
    * @dev Check whether `account` is in blacklist or not
    * @param account account to check
    * @return If in black list => return true; else return false
    */
    function _isInBlackList(address account) internal view returns(bool){
        return _isBlackListed[account];
    }

    //EVENTS
    event AddedToBlackList(address account);
    event RemovedFromBlackList(address account);
}

// SPDX-License-Identifier: MIT
