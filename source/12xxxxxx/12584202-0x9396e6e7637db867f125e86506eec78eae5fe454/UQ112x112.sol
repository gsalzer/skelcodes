// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

/// @dev Library for handling binary fixed point numbers
/// (https://en.wikipedia.org/wiki/Q_(number_format))
library UQ112x112 {
    uint224 constant Q112 = 2**112;

    /// @dev encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112;
    }

    /// @dev // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(
        uint224 x,
        uint112 y
    )
    internal
    pure
    returns (uint224 z) 
    {
        z = x / uint224(y);
    }
}

