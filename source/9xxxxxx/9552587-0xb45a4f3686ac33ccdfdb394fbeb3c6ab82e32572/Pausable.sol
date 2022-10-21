pragma solidity ^0.4.24;

contract Pausable {

    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    function _pause() internal whenNotPaused {
        paused = true;
        emit Pause();
    }

    function _unpause() internal whenPaused {
        paused = false;
        emit Unpause();
    }

}

