// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/// @dev Fixed Point decimal math utils for variable decimal point precision
///      on 256-bit wide numbers
library Fixed256xVar {
    /// @dev Multiplies two variable precision fixed point decimal numbers
    /// @param one 1.0 expressed in the base precision of `a` and `b`
    /// @return result = a * b
    function mulfV(
        uint256 a,
        uint256 b,
        uint256 one
    ) internal pure returns (uint256) {
        // result is always truncated
        return (a * b) / one;
    }

    /// @dev Divides two variable precision fixed point decimal numbers
    /// @param one 1.0 expressed in the base precision of `a` and `b`
    /// @return result = a / b
    function divfV(
        uint256 a,
        uint256 b,
        uint256 one
    ) internal pure returns (uint256) {
        // result is always truncated
        return (a * one) / b;
    }
}

