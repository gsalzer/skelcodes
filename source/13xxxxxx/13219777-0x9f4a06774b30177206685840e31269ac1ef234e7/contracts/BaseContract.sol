// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BaseContract is Pausable, Ownable {
    function togglePausedState() external onlyOwner {
        paused() ? _unpause() : _pause();
    }
}

