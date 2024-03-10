// SPDX-License-Identifier: MIT
pragma solidity =0.7.5;

import "LibBaseAuth.sol";


/**
 * @dev Auth pause.
 */
contract AuthPause is BaseAuth {
    using Roles for Roles.Role;

    bool private _paused = false;

    event PausedON();
    event PausedOFF();


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier onlyNotPaused() {
        require(!_paused, "Paused");
        _;
    }

    /**
     * @return Returns true if the contract is paused, false otherwise.
     */
    function isPaused()
        public
        view
        returns (bool)
    {
        return _paused;
    }

    /**
     * @dev Sets paused state.
     *
     * Can only be called by the current owner.
     */
    function setPaused(bool value)
        external
        onlyAgent
    {
        _paused = value;

        if (_paused) {
            emit PausedON();
        } else {
            emit PausedOFF();
        }
    }
}

