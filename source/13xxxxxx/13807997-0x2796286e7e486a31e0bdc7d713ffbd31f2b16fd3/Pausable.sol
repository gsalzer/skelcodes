// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControlUpgradeable.sol";
import "./ERC20Upgradeable.sol";

abstract contract Pausable is AccessControlUpgradeable {
    /// @notice Flag indicating whether the contract has been paused
    bool private _paused;

    /// @notice Role for access control
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Sets the values for {_paused}.
     */
    function __Paused_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Emitted when the contract is paused
     */
    event Paused();

    /**
     * @dev Emitted when the contract is unpaused
     */
    event Unpaused();

    /**
     * @dev Throws an error if the contract is paused
     */
    modifier notPaused() {
        require(!_paused, "contract is paused");
        _;
    }

    /**
     * @dev Allow only the addresses with the PAUSER_ROLE privileges
     */
    modifier onlyPauser() {
        _checkRole(PAUSER_ROLE, _msgSender());
        _;
    }

    /**
     * @dev Check if the contract is paused
     */
    function isPaused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Pause the contract
     */
    function pause() public onlyPauser {
        if (!_paused) {
            _paused = true;
            emit Paused();
        }
    }

    /**
     * @dev Unpause the contract
     */
    function unpause() public onlyPauser {
        if (_paused) {
            _paused = false;
            emit Unpaused();
        }
    }
}

abstract contract PausableToken is ERC20Upgradeable, Pausable {
    /**
     * @dev Override `_approve` to include pausability
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual override notPaused {
        super._approve(owner, spender, amount);
    }

    /**
     * @dev Pre-transfer hook for running validation.
     *
     * Overridden to perform balance limit validation.
     *
     * The transfer will be deemed valid at the present moment if the following criteria are fulfilled
     * - the contract is not paused
     */
    function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal virtual override {
        require(!isPaused(), "contract is paused");

        super._beforeTokenTransfer(sender, recipient, amount);
    }
}

