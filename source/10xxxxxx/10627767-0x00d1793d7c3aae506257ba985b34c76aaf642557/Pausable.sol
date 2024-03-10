// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Ownable.sol";

contract Pausable is Ownable {
    // For allowing tokens to only become transferable at the end of sale
    address public pauser;
    bool public paused;

    constructor() public Ownable() {
      pauser = msg.sender;
      paused = true;
    }

    modifier onlyPauser() {
        require(pauser == _msgSender(), "Pausable: Only Pauser can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Pausable: Contract is paused");
        _;
    }

    // PAUSER //
    function setPauser(address newPauser) public onlyOwner {
        require(
            newPauser != address(0),
            "Pausable: newPauser is the zero address."
        );
        require(
            pauser != address(0),
            "Pausable: Pauser rights have been burnt. It's no longer able to set newPauser"
        );
        pauser = newPauser;
    }

    function _unpause() internal onlyPauser {
        paused = false;
        // Upon unpausing, burn the rights of becoming pauser.
        pauser = address(0);
    }
}

