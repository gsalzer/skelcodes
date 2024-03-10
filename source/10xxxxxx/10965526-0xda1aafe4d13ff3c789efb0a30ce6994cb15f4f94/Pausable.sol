// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./Ownable.sol";

contract Pausable is Ownable {
    bool private isPaused = false;

    event Paused();
    event Unpaused();

    function pause() public onlyOwner {
        isPaused = true;
    }

    function unpause() public onlyOwner {
        isPaused = false;
    }

    modifier whenPaused {
        require(isPaused, "Contract is not paused");
        _;
    }

    modifier whenNotPaused {
        require(!isPaused, "Contract is paused");
        _;
    }
}

