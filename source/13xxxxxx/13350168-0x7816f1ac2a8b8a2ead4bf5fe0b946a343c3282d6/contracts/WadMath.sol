// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;


/**
 * @title Fixed point arithmetic library
 * @author Alberto Cuesta Cañada, Jacob Eliosoff, Alex Roan
 */
library WadMath {
    uint public constant WAD = 1e18;
    uint public constant WAD_MINUS_1 = WAD - 1;
    uint public constant HALF_WAD = WAD / 2;
    uint public constant FLOOR_LOG_2_WAD_SCALED = 158961593653514369813532673448321674075;  // log2(1e18) * 2**121
    uint public constant  CEIL_LOG_2_WAD_SCALED = 158961593653514369813532673448321674076;  // log2(1e18) * 2**121
    uint public constant FLOOR_LOG_2_E_SCALED_OVER_WAD = 3835341275459348169;               // log2(e) * 2**121 / 1e18
    uint public constant  CEIL_LOG_2_E_SCALED_OVER_WAD = 3835341275459348170;               // log2(e) * 2**121 / 1e18

    function wadMul(uint x, uint y, bool roundUp) internal pure returns (uint z) {
        z = (roundUp ? wadMulUp(x, y) : wadMulDown(x, y));
    }

    function wadMulDown(uint x, uint y) internal pure returns (uint z) {
        z = x * y;                  // Rounds down, truncating the last 18 digits.  So (imagining 2 dec places rather than 18):
        unchecked { z /= WAD; }     // 369 (3.69) * 271 (2.71) -> 99999 (9.9999) -> 999 (9.99).
    }

    function wadMulUp(uint x, uint y) internal pure returns (uint z) {
        z = x * y + WAD_MINUS_1;    // Rounds up.  So (again imagining 2 decimal places):
        unchecked { z /= WAD; }     // 383 (3.83) * 235 (2.35) -> 90005 (9.0005), + 99 (0.0099) -> 90104, / 100 -> 901 (9.01).
    }

    function wadSquaredDown(uint x) internal pure returns (uint z) {
        z = x * x;
        unchecked { z /= WAD; }
    }

    function wadSquaredUp(uint x) internal pure returns (uint z) {
        z = (x * x) + WAD_MINUS_1;
        unchecked { z /= WAD; }
    }

    function wadDiv(uint x, uint y, bool roundUp) internal pure returns (uint z) {
        z = (roundUp ? wadDivUp(x, y) : wadDivDown(x, y));
    }

    function wadDivDown(uint x, uint y) internal pure returns (uint z) {
        z = (x * WAD) / y;          // Rounds down: 199 (1.99) / 1000 (10) -> (199 * 100) / 1000 -> 19 (0.19: 0.199 truncated).
    }

    function wadDivUp(uint x, uint y) internal pure returns (uint z) {
        z = x * WAD + y;            // 101 (1.01) / 1000 (10) -> (101 * 100 + 1000 - 1) / 1000 -> 11 (0.11 = 0.101 rounded up).
        unchecked { z -= 1; }       // Can do unchecked subtraction since division in next line will catch y = 0 case anyway
        z /= y;
    }

    /**
     * @return z The appropriately rounded result of w * x / y, with all three inputs and the result represented in WAD format.
     * This function is based on the following simplification - why divide and then multiply by WAD?
     *
     *        w.wadMul(x).wadDiv(y)
     *     =~ (w * x / WAD) * WAD / y
     *     =~ w * x / y
     *
     */
    function wadMulDivDown(uint w, uint x, uint y) internal pure returns (uint z) {
        z = w * x / y;
    }

    function wadMulDivUp(uint w, uint x, uint y) internal pure returns (uint z) {
        z = w * x + y;              // See wadDivUp() above
        unchecked { z -= 1; }
        z /= y;
    }

    function wadMax(uint x, uint y) internal pure returns (uint z) {
        z = (x > y ? x : y);
    }

    function wadMin(uint x, uint y) internal pure returns (uint z) {
        z = (x < y ? x : y);
    }

    /**
     * @notice Adapted from rpow() in https://github.com/dapphub/ds-math/blob/master/src/math.sol - thank you!
     *
     * This famous algorithm is called "exponentiation by squaring" and calculates x^n with x as fixed-point and n as regular
     * unsigned.
     *
     * It's O(log n), instead of O(n) for naive repeated multiplication.
     *
     * These facts are why it works:
     *
     * 1. If n is even, then x^n = (x^2)^(n/2).
     * 2. If n is odd, then x^n = x * x^(n-1), and substituting the equation for even n gives x^n = x * (x^2)^((n-1)/2).
     * 3. Since EVM division is flooring, n /= 2 will give us the recursive exponent we want in both cases: n/2 for even n, and
     *    (n-1)/2 for odd n.
     *
     * @param x base to raise to power n (x is WAD-scaled)
     * @param n power to raise x to (n is *not* WAD-scaled - ie, passing n = 3 calculates x cubed)
     * @return z x**n, WAD-scaled: so, since x and z are WAD-scaled and n isn't, z = (x / 1e18)**n * 1e18
     */
    function wadPowInt(uint x, uint n) internal pure returns (uint z) {
        unchecked { z = n % 2 != 0 ? x : WAD; }

        unchecked { n /= 2; }
        bool nIsOdd;
        while (n != 0) {
            x = wadMulDown(x, x);

            unchecked { nIsOdd = n % 2 != 0; }
            if (nIsOdd) {
                z = wadMulDown(z, x);
            }
            unchecked { n /= 2; }
        }
    }

    function wadSqrtDown(uint y) internal pure returns (uint root) {
        root = wadPowDown(y, HALF_WAD);
    }

    function wadSqrtUp(uint y) internal pure returns (uint root) {
        root = wadPowUp(y, HALF_WAD);
    }

    /**
     * @return z e raised to the given power `y` (approximately!), specified in WAD 18-digit fixed-point form, and in, again,
     * WAD form.
     * @notice This library works only on positive uint inputs.  If you have a negative exponent (y < 0), you can calculate it
     * using this identity:
     *
     *     wadExpDown(y < 0) = 1 / wadExp(-y > 0) = WAD.div(wadExp(-y > 0))
     *
     * @dev We're given Y = y * 1e18 (WAD-formatted); we want to return Z = z * 1e18, where z =~ e**y; and we have
     * `pow_2(X = x * 2**121)` below, which returns y =~ 2**x = 2**(X / 2**121).  So the math we use is:
     *
     *     K1 = log2(1e18) * 2**121
     *     K2 = log2(e) * 2**121 / 1e18
     *     Z = `pow_2(K1 + K2 * Y)`
     *       = 2**((K1 + K2 * Y) / 2**121)
     *       = 2**((log2(1e18) * 2**121 + (log2(e) * 2**121 / 1e18) * (y * 1e18)) / 2**121)
     *       = 2**(log2(1e18) + log2(e) * y)
     *       = 2**(log2(1e18)) * 2**(log2(e) * y)
     *       = 1e18 * (2**log2(e))**y
     *       = e**y * 1e18
     */
    function wadExpDown(uint y) internal pure returns (uint z) {
        uint exponent = FLOOR_LOG_2_WAD_SCALED + FLOOR_LOG_2_E_SCALED_OVER_WAD * y;
        require(exponent <= type(uint128).max, "exponent overflow");
        z = pow_2(uint128(exponent));
    }

    function wadExpUp(uint y) internal pure returns (uint z) {
        uint exponent = FLOOR_LOG_2_WAD_SCALED - CEIL_LOG_2_E_SCALED_OVER_WAD * y;
        require(exponent <= type(uint128).max, "exponent overflow");
        uint wadOneOverExpY = pow_2(uint128(exponent));
        z = wadDivUp(WAD, wadOneOverExpY);
    }

    /**
     * @return z The given number `x` raised to power `y` (approximately!), with all of `x`, `y` and `z` in WAD 18-digit
     * fixed-point form.
     * @notice This library works only on positive uint inputs.  If you have a negative base (x < 0) or a negative exponent
     * (y < 0), you can calculate them using these identities:
     *
     *     wadPowDown(x < 0, y) = -wadPowDown(-x > 0, y)
     *     wadPowDown(x, y < 0) = 1 / wadPowUp(x, -y > 0) = WAD.div(wadPowUp(x, -y > 0))
     *
     * @dev We're given X = x * 1e18, and Y = y * 1e18 (both WAD-formatted); we want Z = z * 1e18, where z =~ x**y; and
     * we have `log_2(x)`, which returns log2(x) * 2**121, and `pow_2(X = x * 2**121)`, which returns 2**x = 2**(X / 2**121).
     * The math we use is:
     *
     *     K = log2(1e18) * 2**121
     *     Z = `pow_2(K + (log_2(X) - K) * Y / 1e18)`
     *       = 2**((K + (log2(X) * 2**121 - K) * Y / 1e18) / 2**121)
     *       = 2**((log2(1e18) * 2**121 + (log2(x * 1e18) * 2**121 - log2(1e18) * 2**121) * (y * 1e18) / 1e18) / 2**121)
     *       = 2**(log2(1e18) + (log2(x * 1e18) - log2(1e18)) * y)
     *       = 2**(log2(1e18) + log2(x) * y)
     *       = 2**(log2(1e18)) * 2**(log2(x) * y)
     *       = 1e18 * (2**log2(x))**y
     *       = x**y * 1e18
     *
     */
    function wadPowDown(uint x, uint y) internal pure returns (uint z) {
        require(x <= type(uint128).max, "x overflow");
        require(y <= uint(type(int).max), "y overflow");
        // The logic here is: Z = pow_2(FLOOR_LOG_2_WAD_SCALED + (log_2(X) - CEIL_LOG_2_WAD_SCALED) * Y / WAD)
        int exponent = int(uint(log_2(uint128(x))));
        unchecked { exponent -= int(CEIL_LOG_2_WAD_SCALED); }   // No chance of overflow here, both operands too small
        exponent *= int(y);
        unchecked { exponent = exponent / int(WAD) + int(FLOOR_LOG_2_WAD_SCALED); } // Can't overflow (would have in prev line)
        require(exponent >= 0, "exponent underflow");
        require(uint(exponent) <= type(uint128).max, "exponent overflow");
        z = pow_2(uint128(uint(exponent)));     // Apparently Solidity won't let us do this cast in one shot.  Weird eh?
     }

    function wadPowUp(uint x, uint y) internal pure returns (uint z) {
        z = wadDivUp(WAD, wadPowDown(wadDivDown(WAD, x), y));
    }

    /* ____________________ Exponential/logarithm fns borrowed from Yield Protocol ____________________
     *
     * See https://github.com/yieldprotocol/yieldspace-v1/blob/master/contracts/YieldMath.sol for Yield's code, originally
     * developed by the math gurus at https://www.abdk.consulting/.
     */

    /**
     * Calculate base 2 logarithm of an unsigned 128-bit integer number.  Revert in case x is zero.
     *
     * @param x number to calculate base 2 logarithm of
     * @return z base 2 logarithm of x, multiplied by 2^121
     */
    function log_2(uint128 x)
        internal pure returns (uint128 z)
    {
        unchecked {
            require (x != 0, "x = 0");

            uint b = x;

            uint l = 0xFE000000000000000000000000000000;

            if (b < 0x10000000000000000) {l -= 0x80000000000000000000000000000000; b <<= 64;}
            if (b < 0x1000000000000000000000000) {l -= 0x40000000000000000000000000000000; b <<= 32;}
            if (b < 0x10000000000000000000000000000) {l -= 0x20000000000000000000000000000000; b <<= 16;}
            if (b < 0x1000000000000000000000000000000) {l -= 0x10000000000000000000000000000000; b <<= 8;}
            if (b < 0x10000000000000000000000000000000) {l -= 0x8000000000000000000000000000000; b <<= 4;}
            if (b < 0x40000000000000000000000000000000) {l -= 0x4000000000000000000000000000000; b <<= 2;}
            if (b < 0x80000000000000000000000000000000) {l -= 0x2000000000000000000000000000000; b <<= 1;}

            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {/*b >>= 1;*/ l |= 0x10000000000000000;}
            /* Precision reduced to 64 bits
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) l |= 0x1;
            */

            z = uint128(l);
        }
    }

    /**
     * Calculate 2 raised into given power.
     *
     * @param x power to raise 2 into, multiplied by 2^121
     * @return z 2 raised into given power
     */
    function pow_2(uint128 x)
        internal pure returns (uint128 z)
    {
        unchecked {
            uint r = 0x80000000000000000000000000000000;
            if (x & 0x1000000000000000000000000000000 > 0) r = r * 0xb504f333f9de6484597d89b3754abe9f >> 127;
            if (x & 0x800000000000000000000000000000 > 0) r = r * 0x9837f0518db8a96f46ad23182e42f6f6 >> 127;
            if (x & 0x400000000000000000000000000000 > 0) r = r * 0x8b95c1e3ea8bd6e6fbe4628758a53c90 >> 127;
            if (x & 0x200000000000000000000000000000 > 0) r = r * 0x85aac367cc487b14c5c95b8c2154c1b2 >> 127;
            if (x & 0x100000000000000000000000000000 > 0) r = r * 0x82cd8698ac2ba1d73e2a475b46520bff >> 127;
            if (x & 0x80000000000000000000000000000 > 0) r = r * 0x8164d1f3bc0307737be56527bd14def4 >> 127;
            if (x & 0x40000000000000000000000000000 > 0) r = r * 0x80b1ed4fd999ab6c25335719b6e6fd20 >> 127;
            if (x & 0x20000000000000000000000000000 > 0) r = r * 0x8058d7d2d5e5f6b094d589f608ee4aa2 >> 127;
            if (x & 0x10000000000000000000000000000 > 0) r = r * 0x802c6436d0e04f50ff8ce94a6797b3ce >> 127;
            if (x & 0x8000000000000000000000000000 > 0) r = r * 0x8016302f174676283690dfe44d11d008 >> 127;
            if (x & 0x4000000000000000000000000000 > 0) r = r * 0x800b179c82028fd0945e54e2ae18f2f0 >> 127;
            if (x & 0x2000000000000000000000000000 > 0) r = r * 0x80058baf7fee3b5d1c718b38e549cb93 >> 127;
            if (x & 0x1000000000000000000000000000 > 0) r = r * 0x8002c5d00fdcfcb6b6566a58c048be1f >> 127;
            if (x & 0x800000000000000000000000000 > 0) r = r * 0x800162e61bed4a48e84c2e1a463473d9 >> 127;
            if (x & 0x400000000000000000000000000 > 0) r = r * 0x8000b17292f702a3aa22beacca949013 >> 127;
            if (x & 0x200000000000000000000000000 > 0) r = r * 0x800058b92abbae02030c5fa5256f41fe >> 127;
            if (x & 0x100000000000000000000000000 > 0) r = r * 0x80002c5c8dade4d71776c0f4dbea67d6 >> 127;
            if (x & 0x80000000000000000000000000 > 0) r = r * 0x8000162e44eaf636526be456600bdbe4 >> 127;
            if (x & 0x40000000000000000000000000 > 0) r = r * 0x80000b1721fa7c188307016c1cd4e8b6 >> 127;
            if (x & 0x20000000000000000000000000 > 0) r = r * 0x8000058b90de7e4cecfc487503488bb1 >> 127;
            if (x & 0x10000000000000000000000000 > 0) r = r * 0x800002c5c8678f36cbfce50a6de60b14 >> 127;
            if (x & 0x8000000000000000000000000 > 0) r = r * 0x80000162e431db9f80b2347b5d62e516 >> 127;
            if (x & 0x4000000000000000000000000 > 0) r = r * 0x800000b1721872d0c7b08cf1e0114152 >> 127;
            if (x & 0x2000000000000000000000000 > 0) r = r * 0x80000058b90c1aa8a5c3736cb77e8dff >> 127;
            if (x & 0x1000000000000000000000000 > 0) r = r * 0x8000002c5c8605a4635f2efc2362d978 >> 127;
            if (x & 0x800000000000000000000000 > 0) r = r * 0x800000162e4300e635cf4a109e3939bd >> 127;
            if (x & 0x400000000000000000000000 > 0) r = r * 0x8000000b17217ff81bef9c551590cf83 >> 127;
            if (x & 0x200000000000000000000000 > 0) r = r * 0x800000058b90bfdd4e39cd52c0cfa27c >> 127;
            if (x & 0x100000000000000000000000 > 0) r = r * 0x80000002c5c85fe6f72d669e0e76e411 >> 127;
            if (x & 0x80000000000000000000000 > 0) r = r * 0x8000000162e42ff18f9ad35186d0df28 >> 127;
            if (x & 0x40000000000000000000000 > 0) r = r * 0x80000000b17217f84cce71aa0dcfffe7 >> 127;
            if (x & 0x20000000000000000000000 > 0) r = r * 0x8000000058b90bfc07a77ad56ed22aaa >> 127;
            if (x & 0x10000000000000000000000 > 0) r = r * 0x800000002c5c85fdfc23cdead40da8d6 >> 127;
            if (x & 0x8000000000000000000000 > 0) r = r * 0x80000000162e42fefc25eb1571853a66 >> 127;
            if (x & 0x4000000000000000000000 > 0) r = r * 0x800000000b17217f7d97f692baacded5 >> 127;
            if (x & 0x2000000000000000000000 > 0) r = r * 0x80000000058b90bfbead3b8b5dd254d7 >> 127;
            if (x & 0x1000000000000000000000 > 0) r = r * 0x8000000002c5c85fdf4eedd62f084e67 >> 127;
            if (x & 0x800000000000000000000 > 0) r = r * 0x800000000162e42fefa58aef378bf586 >> 127;
            if (x & 0x400000000000000000000 > 0) r = r * 0x8000000000b17217f7d24a78a3c7ef02 >> 127;
            if (x & 0x200000000000000000000 > 0) r = r * 0x800000000058b90bfbe9067c93e474a6 >> 127;
            if (x & 0x100000000000000000000 > 0) r = r * 0x80000000002c5c85fdf47b8e5a72599f >> 127;
            if (x & 0x80000000000000000000 > 0) r = r * 0x8000000000162e42fefa3bdb315934a2 >> 127;
            if (x & 0x40000000000000000000 > 0) r = r * 0x80000000000b17217f7d1d7299b49c46 >> 127;
            if (x & 0x20000000000000000000 > 0) r = r * 0x8000000000058b90bfbe8e9a8d1c4ea0 >> 127;
            if (x & 0x10000000000000000000 > 0) r = r * 0x800000000002c5c85fdf4745969ea76f >> 127;
            if (x & 0x8000000000000000000 > 0) r = r * 0x80000000000162e42fefa3a0df5373bf >> 127;
            if (x & 0x4000000000000000000 > 0) r = r * 0x800000000000b17217f7d1cff4aac1e1 >> 127;
            if (x & 0x2000000000000000000 > 0) r = r * 0x80000000000058b90bfbe8e7db95a2f1 >> 127;
            if (x & 0x1000000000000000000 > 0) r = r * 0x8000000000002c5c85fdf473e61ae1f8 >> 127;
            if (x & 0x800000000000000000 > 0) r = r * 0x800000000000162e42fefa39f121751c >> 127;
            if (x & 0x400000000000000000 > 0) r = r * 0x8000000000000b17217f7d1cf815bb96 >> 127;
            if (x & 0x200000000000000000 > 0) r = r * 0x800000000000058b90bfbe8e7bec1e0d >> 127;
            if (x & 0x100000000000000000 > 0) r = r * 0x80000000000002c5c85fdf473dee5f17 >> 127;
            if (x & 0x80000000000000000 > 0) r = r * 0x8000000000000162e42fefa39ef5438f >> 127;
            if (x & 0x40000000000000000 > 0) r = r * 0x80000000000000b17217f7d1cf7a26c8 >> 127;
            if (x & 0x20000000000000000 > 0) r = r * 0x8000000000000058b90bfbe8e7bcf4a4 >> 127;
            if (x & 0x10000000000000000 > 0) r = r * 0x800000000000002c5c85fdf473de72a2 >> 127;
            /* Precision reduced to 64 bits
            if (x & 0x8000000000000000 > 0) r = r * 0x80000000000000162e42fefa39ef3765 >> 127;
            if (x & 0x4000000000000000 > 0) r = r * 0x800000000000000b17217f7d1cf79b37 >> 127;
            if (x & 0x2000000000000000 > 0) r = r * 0x80000000000000058b90bfbe8e7bcd7d >> 127;
            if (x & 0x1000000000000000 > 0) r = r * 0x8000000000000002c5c85fdf473de6b6 >> 127;
            if (x & 0x800000000000000 > 0) r = r * 0x800000000000000162e42fefa39ef359 >> 127;
            if (x & 0x400000000000000 > 0) r = r * 0x8000000000000000b17217f7d1cf79ac >> 127;
            if (x & 0x200000000000000 > 0) r = r * 0x800000000000000058b90bfbe8e7bcd6 >> 127;
            if (x & 0x100000000000000 > 0) r = r * 0x80000000000000002c5c85fdf473de6a >> 127;
            if (x & 0x80000000000000 > 0) r = r * 0x8000000000000000162e42fefa39ef35 >> 127;
            if (x & 0x40000000000000 > 0) r = r * 0x80000000000000000b17217f7d1cf79a >> 127;
            if (x & 0x20000000000000 > 0) r = r * 0x8000000000000000058b90bfbe8e7bcd >> 127;
            if (x & 0x10000000000000 > 0) r = r * 0x800000000000000002c5c85fdf473de6 >> 127;
            if (x & 0x8000000000000 > 0) r = r * 0x80000000000000000162e42fefa39ef3 >> 127;
            if (x & 0x4000000000000 > 0) r = r * 0x800000000000000000b17217f7d1cf79 >> 127;
            if (x & 0x2000000000000 > 0) r = r * 0x80000000000000000058b90bfbe8e7bc >> 127;
            if (x & 0x1000000000000 > 0) r = r * 0x8000000000000000002c5c85fdf473de >> 127;
            if (x & 0x800000000000 > 0) r = r * 0x800000000000000000162e42fefa39ef >> 127;
            if (x & 0x400000000000 > 0) r = r * 0x8000000000000000000b17217f7d1cf7 >> 127;
            if (x & 0x200000000000 > 0) r = r * 0x800000000000000000058b90bfbe8e7b >> 127;
            if (x & 0x100000000000 > 0) r = r * 0x80000000000000000002c5c85fdf473d >> 127;
            if (x & 0x80000000000 > 0) r = r * 0x8000000000000000000162e42fefa39e >> 127;
            if (x & 0x40000000000 > 0) r = r * 0x80000000000000000000b17217f7d1cf >> 127;
            if (x & 0x20000000000 > 0) r = r * 0x8000000000000000000058b90bfbe8e7 >> 127;
            if (x & 0x10000000000 > 0) r = r * 0x800000000000000000002c5c85fdf473 >> 127;
            if (x & 0x8000000000 > 0) r = r * 0x80000000000000000000162e42fefa39 >> 127;
            if (x & 0x4000000000 > 0) r = r * 0x800000000000000000000b17217f7d1c >> 127;
            if (x & 0x2000000000 > 0) r = r * 0x80000000000000000000058b90bfbe8e >> 127;
            if (x & 0x1000000000 > 0) r = r * 0x8000000000000000000002c5c85fdf47 >> 127;
            if (x & 0x800000000 > 0) r = r * 0x800000000000000000000162e42fefa3 >> 127;
            if (x & 0x400000000 > 0) r = r * 0x8000000000000000000000b17217f7d1 >> 127;
            if (x & 0x200000000 > 0) r = r * 0x800000000000000000000058b90bfbe8 >> 127;
            if (x & 0x100000000 > 0) r = r * 0x80000000000000000000002c5c85fdf4 >> 127;
            if (x & 0x80000000 > 0) r = r * 0x8000000000000000000000162e42fefa >> 127;
            if (x & 0x40000000 > 0) r = r * 0x80000000000000000000000b17217f7d >> 127;
            if (x & 0x20000000 > 0) r = r * 0x8000000000000000000000058b90bfbe >> 127;
            if (x & 0x10000000 > 0) r = r * 0x800000000000000000000002c5c85fdf >> 127;
            if (x & 0x8000000 > 0) r = r * 0x80000000000000000000000162e42fef >> 127;
            if (x & 0x4000000 > 0) r = r * 0x800000000000000000000000b17217f7 >> 127;
            if (x & 0x2000000 > 0) r = r * 0x80000000000000000000000058b90bfb >> 127;
            if (x & 0x1000000 > 0) r = r * 0x8000000000000000000000002c5c85fd >> 127;
            if (x & 0x800000 > 0) r = r * 0x800000000000000000000000162e42fe >> 127;
            if (x & 0x400000 > 0) r = r * 0x8000000000000000000000000b17217f >> 127;
            if (x & 0x200000 > 0) r = r * 0x800000000000000000000000058b90bf >> 127;
            if (x & 0x100000 > 0) r = r * 0x80000000000000000000000002c5c85f >> 127;
            if (x & 0x80000 > 0) r = r * 0x8000000000000000000000000162e42f >> 127;
            if (x & 0x40000 > 0) r = r * 0x80000000000000000000000000b17217 >> 127;
            if (x & 0x20000 > 0) r = r * 0x8000000000000000000000000058b90b >> 127;
            if (x & 0x10000 > 0) r = r * 0x800000000000000000000000002c5c85 >> 127;
            if (x & 0x8000 > 0) r = r * 0x80000000000000000000000000162e42 >> 127;
            if (x & 0x4000 > 0) r = r * 0x800000000000000000000000000b1721 >> 127;
            if (x & 0x2000 > 0) r = r * 0x80000000000000000000000000058b90 >> 127;
            if (x & 0x1000 > 0) r = r * 0x8000000000000000000000000002c5c8 >> 127;
            if (x & 0x800 > 0) r = r * 0x800000000000000000000000000162e4 >> 127;
            if (x & 0x400 > 0) r = r * 0x8000000000000000000000000000b172 >> 127;
            if (x & 0x200 > 0) r = r * 0x800000000000000000000000000058b9 >> 127;
            if (x & 0x100 > 0) r = r * 0x80000000000000000000000000002c5c >> 127;
            if (x & 0x80 > 0) r = r * 0x8000000000000000000000000000162e >> 127;
            if (x & 0x40 > 0) r = r * 0x80000000000000000000000000000b17 >> 127;
            if (x & 0x20 > 0) r = r * 0x8000000000000000000000000000058b >> 127;
            if (x & 0x10 > 0) r = r * 0x800000000000000000000000000002c5 >> 127;
            if (x & 0x8 > 0) r = r * 0x80000000000000000000000000000162 >> 127;
            if (x & 0x4 > 0) r = r * 0x800000000000000000000000000000b1 >> 127;
            if (x & 0x2 > 0) r = r * 0x80000000000000000000000000000058 >> 127;
            if (x & 0x1 > 0) r = r * 0x8000000000000000000000000000002c >> 127;
            */

            r >>= 127 - (x >> 121);

            z = uint128(r);
        }
    }
}

