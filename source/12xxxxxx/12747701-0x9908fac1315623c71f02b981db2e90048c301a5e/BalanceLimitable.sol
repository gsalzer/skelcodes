// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControlUpgradeable.sol";
import "./ERC20Upgradeable.sol";

abstract contract BalanceLimitableToken is ERC20Upgradeable, AccessControlUpgradeable {
    /// @notice Maximum token balance addresses are allowed to have
    uint256 private _balanceLimit;
    /// @notice Record of addresses that are allowed to circumvent the balance limit
    mapping (address => bool) private _balanceLimitBypass;

    /// @notice Role for access control
    bytes32 public constant BALANCE_LIMITER_ROLE = keccak256("BALANCE_LIMITER_ROLE");

    /**
     * @dev Sets the values for {_balanceLimit}.
     */
    function __BalanceLimitableToken_init_unchained(uint256 balanceLimit_) internal initializer {
        _setBalanceLimit(balanceLimit_);
    }

    /**
     * @dev Emitted when an address is added to the bypass list
     */
    event BalanceLimitBypassAdded(address bypasser);

    /**
     * @dev Emitted when an address is removed from the bypass list
     */
    event BalanceLimitBypassRemoved(address exBypasser);

    /**
     * @dev Emitted when the balance limit is changed
     */
    event BalanceLimitChange(uint256 oldLimit, uint256 newLimit);

    /**
     * @dev Allow only the addresses with the BALANCE_LIMITER_ROLE privileges
     */
    modifier onlyBalanceLimiter() {
        _checkRole(BALANCE_LIMITER_ROLE, _msgSender());
        _;
    }

    /**
     * @dev Allow `bypasser` to circumvent the balance limit
     */
    function addBalanceBypasser(address bypasser) public virtual onlyBalanceLimiter {
        _addBalanceBypasser(bypasser);
    }

    /**
     * @dev Returns the max allowed balance
     */
    function balanceLimit() public view virtual returns (uint256) {
        return _balanceLimit;
    }

    /**
     * @dev Check if `target` is allowed to bypass the balance limit
     */
    function bypassesBalanceLimit(address target) public view virtual returns (bool) {
        return _balanceLimitBypass[target];
    }

    /**
     * @dev Revoke balance limit bypass privileges from `exBypasser`
     */
    function removeBalanceBypasser(address exBypasser) public virtual onlyBalanceLimiter {
        _removeBalanceBypasser(exBypasser);
    }

    /**
     * @dev Update the max allowed balance
     */
    function setBalanceLimit(uint256 newBalanceLimit) public virtual onlyBalanceLimiter {
        _setBalanceLimit(newBalanceLimit);
    }

    /**
     * @dev Allow `bypasser` to circumvent the balance limit
     */
    function _addBalanceBypasser(address bypasser) internal virtual {
        if (!_balanceLimitBypass[bypasser]) {
            _balanceLimitBypass[bypasser] = true;
            emit BalanceLimitBypassAdded(bypasser);
        }
    }

    /**
     * @dev Pre-transfer hook for running validation.
     *
     * Overridden to perform balance limit validation.
     *
     * The transfer will be deemed valid at the present moment if the following criteria are fulfilled
     * - the balance of `sender` is equal to or more than `amount`
     * - the new balance of `recipient` after adding `amount` does not exceed the balance limit, or
     * - `recipient` is a bypasser (i.e. is an address in the bypass list)
     */
    function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal virtual override {
        require(
            recipient == address(0) ||
                bypassesBalanceLimit(recipient) ||
                (balanceOf(recipient) + amount) <= _balanceLimit,
            "balance limit exceeded"
        );

        super._beforeTokenTransfer(sender, recipient, amount);
    }

    /**
     * @dev Revoke balance limit bypass privileges from `exBypasser`
     */
    function _removeBalanceBypasser(address exBypasser) internal virtual {
        if (_balanceLimitBypass[exBypasser]) {
            _balanceLimitBypass[exBypasser] = false;
            emit BalanceLimitBypassRemoved(exBypasser);
        }
    }

    /**
     * @dev Update the max allowed balance
     */
    function _setBalanceLimit(uint256 newBalanceLimit) internal virtual {
        if (_balanceLimit != newBalanceLimit) {
            uint256 oldLimit = _balanceLimit;
            _balanceLimit = newBalanceLimit;
            emit BalanceLimitChange(oldLimit, newBalanceLimit);
        }
    }
}

