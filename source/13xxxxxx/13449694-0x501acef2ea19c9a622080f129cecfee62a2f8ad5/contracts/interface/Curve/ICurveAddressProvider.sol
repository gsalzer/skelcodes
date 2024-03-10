// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface ICurveAddressProvider {
    
    /**
     * @notice Returns `CurveRegistry` address.
     * @return registry The registry address.
     */
    // solhint-disable-next-line func-name-mixedcase
    function get_registry() external view returns (address registry);
}

