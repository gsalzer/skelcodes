// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Libraries
import "./Address.sol";
import "./SafeMath.sol";

/**
    @notice This library manages the functions for the logic version struct.
 */
library LogicVersionLib {
    using SafeMath for uint256;
    using Address for address;

    /**
        @notice It stores all the versions for a given logic.
        @param currentVersion the current version.
        @param latestVersion the latest version.
        @param versions mapping version to logic address.
        @param exists boolean to test whether this logic version exists or not.
     */
    struct LogicVersion {
        uint256 currentVersion;
        uint256 latestVersion;
        mapping(uint256 => address) versions;
        bool exists;
    }

    /**
        @notice It creates a new logic version.
        @param self the current logic version instance.
        @param logic initial logic address.
     */
    function initialize(LogicVersion storage self, address logic) internal {
        requireNotExists(self);
        require(logic.isContract(), "LOGIC_MUST_BE_CONTRACT");
        self.currentVersion = 0;
        self.latestVersion = 0;
        self.versions[self.currentVersion] = logic;
        self.exists = true;
    }

    /**
        @notice It rollbacks a logic to a previous version.
        @param self the current logic version instance.
        @param previousVersion the previous version to be used.
     */
    function rollback(LogicVersion storage self, uint256 previousVersion)
        internal
        returns (
            uint256 currentVersion,
            address previousLogic,
            address newLogic
        )
    {
        requireExists(self);
        require(
            self.currentVersion != previousVersion,
            "CURRENT_VERSION_MUST_BE_DIFF"
        );
        require(
            self.latestVersion >= previousVersion,
            "VERSION_MUST_BE_LTE_LATEST"
        );
        currentVersion = self.currentVersion;
        previousLogic = self.versions[self.currentVersion];
        newLogic = self.versions[previousVersion];

        self.currentVersion = previousVersion;
    }

    /**
        @notice Checks whether the current logic version exists or not.
        @dev It throws a require error if the logic version already exists.
        @param self the current logic version.
     */
    function requireNotExists(LogicVersion storage self) internal view {
        require(!self.exists, "LOGIC_ALREADY_EXISTS");
    }

    /**
        @notice Checks whether the current logic version exists or not.
        @dev It throws a require error if the current logic version doesn't exist.
        @param self the current logic version.
     */
    function requireExists(LogicVersion storage self) internal view {
        require(self.exists, "LOGIC_NOT_EXISTS");
    }

    /**
        @notice It upgrades a logic version.
        @dev It throws a require error if:
            - The new logic is equal to the current logic.
        @param self the current logic version.
        @param newLogic the new logic to set in the logic version.
        @return oldLogic the old logic address.
        @return oldVersion the old version.
        @return newVersion the new version.
     */
    function upgrade(LogicVersion storage self, address newLogic)
        internal
        returns (
            address oldLogic,
            uint256 oldVersion,
            uint256 newVersion
        )
    {
        requireExists(self);
        require(
            self.versions[self.currentVersion] != newLogic,
            "NEW_LOGIC_REQUIRED"
        );
        require(newLogic.isContract(), "LOGIC_MUST_BE_CONTRACT");
        oldLogic = self.versions[self.currentVersion];
        oldVersion = self.currentVersion;
        newVersion = self.latestVersion.add(1);

        self.currentVersion = newVersion;
        self.latestVersion = newVersion;
        self.versions[newVersion] = newLogic;
    }
}

