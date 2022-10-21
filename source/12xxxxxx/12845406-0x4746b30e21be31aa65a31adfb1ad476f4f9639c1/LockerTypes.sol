// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev Base datstructures for Locker contracts set
 * 
 */
abstract contract LockerTypes {
    //Just enum for good readability
    enum LockType {ERC20, LP}
    
    //Lock storage record
    struct  LockStorageRecord {
        LockType ltype;  //Most time it equal ERC20
        address token;   //Address of project token smart contract to lock
        uint256 amount;  //Lock amount for all investors/lendings
        VestingRecord[] vestings; //Array of vedtings records (see below)
    }

    //One vesting record
    struct VestingRecord {
        uint256 unlockTime;  //only after this moment locked amount will be available
        uint256 amountUnlock;//after unlockTime this amount will be available for all investors according  percentage share
        bool isNFT; //for use with futeres lock
    }

    //Investor's share record
    struct RegistryShare {
        uint256 lockIndex;     //Array index of lock record
        uint256 sharePercent;  //Investors share in this lock
        uint256 claimedAmount; //Already claimed amount
    }

}
