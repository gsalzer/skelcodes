pragma solidity ^0.6.0;

import "./ERC20Pausable.sol";

contract MELOS is ERC20Pausable {
    constructor () public ERC20("MELOS", "MELOS") {
        _setupDecimals(4);
        _mint(_msgSender(), 1000000000 * 10**4);
    }

    function pause() external {
        _pause();
    }

    function unpause() external {
        _unpause();
    }


    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

