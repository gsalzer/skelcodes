// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./EIP1967/EIP1967Reader.sol";
import "./EIP1967/EIP1967Writer.sol";

/**
 * Provides an `implementationInitializer` modifier for preventing multiple
 * calls of the `initialize()` method.
 */
abstract contract InitializableUpgrades is EIP1967Reader, EIP1967Writer {
    /**
     * Address of the implementation contract which was initialized the last time
     */
    address private _implementationInitialized;

    /**
     * Keeps track of the latest implementation's `initialize()` call and prevents
     * its calls outside of the upgrade process
     */
    modifier implementationInitializer() {
        require(
            _implementationInitialized != implementation(),
            "already upgraded"
        );

        _;

        _implementationInitialized = implementation();
    }

    /**
     * This function is called upon implementation initialization and immediately
     * after the upgrade has happened
     */
    // solhint-disable-next-line no-empty-blocks
    function initialize() external virtual implementationInitializer {}

    /**
     * Returns the address to which the fallback calls should be delegated to.
     */
    function implementation() public view returns (address) {
        return _implementationAddress();
    }

    // Reserved storage space to allow for layout changes in the future.
    // solhint-disable-next-line ordering
    uint256[49] private __gap;
}

