pragma solidity ^0.5.0;

import './ERC20.sol';
import './Pausable.sol';
import './Lockable.sol';

/**
 * @title Pausable token
 * @dev ERC20 modified with pausable transfers. 
 */
contract ERC20Pausable is ERC20, Pausable,Lockable {
    
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        require(!isLock(msg.sender));
        require(!isLock(to));
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        require(!isLock(msg.sender));
        require(!isLock(from));
        require(!isLock(to));
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        require(!isLock(msg.sender));
        require(!isLock(spender));
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool) {
        require(!isLock(msg.sender));
        require(!isLock(spender));
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool) {
        require(!isLock(msg.sender));
        require(!isLock(spender));
        return super.decreaseAllowance(spender, subtractedValue);
    }
}

