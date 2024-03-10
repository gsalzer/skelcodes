// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @notice Wraps the default admin role from OpenZeppelin's AccessControl for easy integration.
 */
abstract contract MomentsAdminRole is Initializable, AccessControlUpgradeable {
    function _initializeAdminRole(address admin) internal initializer {
        AccessControlUpgradeable.__AccessControl_init();
        // Grant the role to a specified account
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    modifier onlyMomentsAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "AdminRole: caller does not have the Admin role"
        );
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
     * @dev onlyAdmin is enforced by `grantRole`.
     */
    function grantAdmin(address account) external {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
     * @dev onlyAdmin is enforced by `revokeRole`.
     */
    function revokeAdmin(address account) external {
        revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

    uint256[1000] private __gap;
}

