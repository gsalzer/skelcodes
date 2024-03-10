// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

library Math {
    
    /// @dev Returns the smallest of two numbers.
    function min(
        uint x, 
        uint y
    ) 
    internal 
    pure 
    returns (uint z) 
    {
        z = x < y ? x : y;
    }

    /// @dev babylonian method 
    ///(https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

