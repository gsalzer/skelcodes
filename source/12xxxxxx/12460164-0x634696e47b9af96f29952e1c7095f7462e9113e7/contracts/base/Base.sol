//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

// Contracts
import "../roles/RolesManagerConsts.sol";
import "../settings/PlatformSettingsConsts.sol";

// Libraries
import "@openzeppelin/contracts/utils/Address.sol";

// Interfaces
import "../settings/IPlatformSettings.sol";
import "../roles/IRolesManager.sol";

abstract contract Base {
    using Address for address;

    /* Constant Variables */

    /* State Variables */

    address public settings;

    /* Modifiers */

    modifier whenPlatformIsPaused() {
        require(_settings().isPaused(), "PLATFORM_ISNT_PAUSED");
        _;
    }

    modifier whenPlatformIsNotPaused() {
        require(!_settings().isPaused(), "PLATFORM_IS_PAUSED");
        _;
    }

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

    modifier onlyConfigurator(address account) {
        _requireHasRole(
            RolesManagerConsts(_rolesManager().consts()).CONFIGURATOR_ROLE(),
            account,
            "SENDER_ISNT_CONFIGURATOR"
        );
        _;
    }

    modifier onlyPauser(address account) {
        _requireHasRole(
            RolesManagerConsts(_rolesManager().consts()).PAUSER_ROLE(),
            account,
            "SENDER_ISNT_PAUSER"
        );
        _;
    }

    /* Constructor */

    constructor(address settingsAddress) internal {
        require(settingsAddress.isContract(), "SETTINGS_MUST_BE_CONTRACT");
        settings = settingsAddress;
    }

    function setSettings(address newSettings) external onlyOwner(msg.sender) {
        require(newSettings.isContract(), "SETTINGS_MUST_BE_CONTRACT");
        require(newSettings != settings, "SETTINGS_MUST_BE_NEW");
        address oldSettings = settings;
        settings = newSettings;
        emit PlatformSettingsUpdated(oldSettings, newSettings);
    }

    /** Internal Functions */

    function _settings() internal view returns (IPlatformSettings) {
        return IPlatformSettings(settings);
    }

    function _settingsConsts() internal view returns (PlatformSettingsConsts) {
        return PlatformSettingsConsts(_settings().consts());
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

    function _getPlatformSettingsValue(bytes32 name) internal view returns (uint256) {
        return _settings().getSettingValue(name);
    }

    /** Events */

    event PlatformSettingsUpdated(address indexed oldSettings, address indexed newSettings);
}

