pragma solidity ^0.5.3;

import { Owned } from "./Ownable.sol";

contract Pausable is Owned{
    bool public isPaused;
    
    event Pause(address _owner, uint _timestamp);
    event Unpause(address _owner, uint _timestamp);
    
    modifier whenPaused {
        require(isPaused);
        _;
    }
    
    modifier whenNotPaused {
        require(!isPaused);
        _;
    }
    
    function pause() public onlyOwner whenNotPaused {
        isPaused = true;
        emit Pause(msg.sender, now);
    }
    
    function unpause() public onlyOwner whenPaused {
        isPaused = false;
        emit Unpause(msg.sender, now);
    }
}

