// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Ownable.sol";

abstract contract Pausable is Ownable {
    event Paused(address account);
    event Unpaused(address account);

    bool public paused;

    constructor ()  {
        paused = false;
    }

    modifier WhenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier WhenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    function Pause() public onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    function Unpause() public onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }
}
