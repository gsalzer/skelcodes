// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC20Unburnable.sol";
import "./Pausable.sol";

/**
 * OpenZeppelin ERC20Pausable based on ERC20Unbernable
 */
abstract contract ERC20PausableUnburnable is ERC20Unburnable, Pausable {

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20PausableUnburnable: token transfer while paused");
    }
}
