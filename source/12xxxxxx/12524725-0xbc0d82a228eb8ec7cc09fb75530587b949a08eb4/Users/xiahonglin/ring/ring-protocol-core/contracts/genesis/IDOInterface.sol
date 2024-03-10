// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

/// @title IDO interface
/// @author Ring Protocol
interface IDOInterface {
    // ----------- Events -----------

    event Deploy(uint256 _amountRusd, uint256 _amountRing);

    // ----------- Genesis Group only state changing API -----------

    function deploy() external;

    // ----------- Governor only state changing API -----------

    function collect(address to) external;

    function unlockLiquidity(address to) external;

}

