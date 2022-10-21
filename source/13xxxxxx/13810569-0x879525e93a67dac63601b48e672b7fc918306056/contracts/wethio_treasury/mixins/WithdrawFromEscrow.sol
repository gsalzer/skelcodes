// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.4;

import "../interfaces/ISendValueWithFallbackWithdraw.sol";
import "../mixins/roles/AdminRole.sol";

/**
 * @notice Allows recovery of funds that were not successfully transferred directly by the market.
 */
abstract contract WithdrawFromEscrow is AdminRole {
    function withdrawFromEscrow(ISendValueWithFallbackWithdraw market)
        external
        onlyAdmin
    {
        market.withdraw();
    }
}

