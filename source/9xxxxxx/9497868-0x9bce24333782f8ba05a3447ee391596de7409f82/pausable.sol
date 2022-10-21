pragma solidity ^0.6.0;

import "./pauser.sol";

contract Pausable is Pauser {
    bool private _stats;
    
    event Paused(address account);
    event unPaused(address account);
    
    constructor () internal {
        _stats = false;
    }
    
    function isPause() public view returns (bool) {
        return _stats;
    }
    
    modifier notPaused() {
        require(!_stats, "paused.");
        _;
    }
    
    modifier isPaused() {
        require(_stats, "not paused.");
        _;
    }
    
    function pause() public isPauser notPaused {
        _stats = true;
        emit Paused(_msgSender());
    }
    
    function unpause() public isPauser isPaused {
        _stats = false;
        emit unPaused(_msgSender());
    }
}


