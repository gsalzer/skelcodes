// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Context.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";


contract ERC20Kinglory is Context, ERC20Burnable, ERC20Pausable {


    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol, initialSupply) {
        
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(owner()==_msgSender(), "ERC20Pausable: must have contract owner");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(owner()==_msgSender(), "ERC20Pausable: must have contract owner");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
