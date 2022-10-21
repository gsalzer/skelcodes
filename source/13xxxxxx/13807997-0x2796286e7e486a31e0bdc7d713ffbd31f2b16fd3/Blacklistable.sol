// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControlUpgradeable.sol";
import "./ERC20Upgradeable.sol";

abstract contract Blacklistable is AccessControlUpgradeable {
    /// @notice Record of blacklisted addresses
    mapping (address => bool) private _prison;

    /// @notice Role for access control
    bytes32 public constant BLACKLISTER_ROLE = keccak256("BLACKLISTER_ROLE");

    /**
     * @dev Emitted when an address is added to the blacklist
     */
    event Blacklisted(address indexed convict);

    /**
     * @dev Emitted when an address is removed from the blacklist
     */
    event Unblacklisted(address indexed parolee);

    /**
     * @dev Throws an error if `target` is blacklisted
     */
    modifier notBlacklisted() {
        require(!isBlacklisted(_msgSender()), "blacklisted");
        _;
    }

    /**
     * @dev Allow only the addresses with the BLACKLISTER_ROLE privileges
     */
    modifier onlyBlacklister() {
        _checkRole(BLACKLISTER_ROLE, _msgSender());
        _;
    }

    /**
     * @dev Add `convict` to the blacklist
     */
    function blacklist(address convict) public virtual onlyBlacklister {
        _blacklist(convict);
    }

    /**
     * @dev Check if `suspect` is blacklisted
     */
    function isBlacklisted(address suspect) public view virtual returns (bool) {
        return _prison[suspect];
    }

    /**
     * @dev Remove `parolee` from the blacklist
     */
    function unblacklist(address parolee) public virtual onlyBlacklister {
        _unblacklist(parolee);
    }

    /**
     * @dev Add `convict` to the blacklist
     */
    function _blacklist(address convict) internal virtual {
        if (!isBlacklisted(convict)) {
            _prison[convict] = true;
            emit Blacklisted(convict);
        }
    }

    /**
     * @dev Remove `parolee` from the blacklist
     */
    function _unblacklist(address parolee) internal virtual {
        if (isBlacklisted(parolee)) {
            _prison[parolee] = false;
            emit Unblacklisted(parolee);
        }
    }
}

abstract contract BlacklistableToken is ERC20Upgradeable, Blacklistable {
    /**
     * @dev Pre-transfer hook for running validation.
     *
     * Overridden to perform blacklist validation.
     *
     * The transfer will be deemed valid at the present moment if the following criteria are fulfilled
     * - `sender` is not blacklisted
     * - `recipient` is not blacklisted
     */
    function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal virtual override {
        require(!isBlacklisted(sender), "blacklisted sender");
        require(!isBlacklisted(recipient), "blacklisted recipient");

        super._beforeTokenTransfer(sender, recipient, amount);
    }
}

