pragma solidity ^0.5.0;

import './PauserRole.sol';

/**
 * @title Lockable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Lockable is PauserRole{

    mapping (address => bool) private lockers;
    
    event LockAccount(address account, bool islock);
    
    /**
     * @dev Check if the account is locked.
     * @param account specific account address.
     */
    function isLock(address account) public view returns (bool) {
        return lockers[account];
    }
    
    /**
     * @dev Lock or thaw account address
     * @param account specific account address.
     * @param islock true lock, false thaw.
     */
    function lock(address account, bool islock)  public onlyPauser {
        lockers[account] = islock;
        emit LockAccount(account, islock);
    }
}
