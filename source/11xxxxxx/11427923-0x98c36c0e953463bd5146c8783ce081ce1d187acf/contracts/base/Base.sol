//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

// Contracts
import "../roles/RolesManagerConsts.sol";

// Libraries
import "@openzeppelin/contracts/utils/Address.sol";

// Interfaces
import "../settings/IPlatformSettings.sol";
import "../roles/IRolesManager.sol";

abstract contract Base {
    using Address for address;

    /* Constant Variables */

    /* State Variables */

    address private settings;

    /* Modifiers */

    modifier onlyOwner(address account) {
        _requireHasRole(
            RolesManagerConsts(_rolesManager().consts()).OWNER_ROLE(),
            account,
            "SENDER_ISNT_OWNER"
        );
        _;
    }

    modifier onlyMinter(address account) {
        _requireHasRole(
            RolesManagerConsts(_rolesManager().consts()).MINTER_ROLE(),
            account,
            "SENDER_ISNT_MINTER"
        );
        _;
    }

    /* Constructor */

    constructor(address settingsAddress) internal {
        require(settingsAddress.isContract(), "SETTINGS_MUST_BE_CONTRACT");
        settings = settingsAddress;
    }

    /** Internal Functions */

    function _settings() internal view returns (IPlatformSettings) {
        return IPlatformSettings(settings);
    }

    function _rolesManager() internal view returns (IRolesManager) {
        return IRolesManager(IPlatformSettings(settings).rolesManager());
    }

    function _requireHasRole(
        bytes32 role,
        address account,
        string memory message
    ) internal view {
        IRolesManager rolesManager = _rolesManager();
        rolesManager.requireHasRole(role, account, message);
    }
}

