pragma solidity ^0.6.0;

import "./Pausable.sol";
import "./ERC20.sol";
import "./Context.sol";
import "./Ownable.sol";

contract StableToken is Context, ERC20, Pausable, Ownable  {
    constructor (string memory name,string memory symbol, uint8 initialDecimals) public ERC20(name, symbol)
    {
      _setupDecimals(initialDecimals);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public onlyOwner {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Issue `amount` tokens for the caller.
     *
     * See {ERC20-_mint}.
     */
    function issue(uint256 amount) public onlyOwner {
        _mint(_msgSender(), amount);
    }


    /**
     * @dev Pause contract
     *
     * See {Pausable-_pause}.
     */
    function pause() public  onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause contract
     *
     * See {Pausable-_unpause}.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

