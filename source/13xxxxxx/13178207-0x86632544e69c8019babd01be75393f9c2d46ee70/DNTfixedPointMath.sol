// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @notice Emitted when the input is greater than 133.084258667509499441.
error _ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error _Exp2InputTooBig(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error _DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error _DivOverflow(uint256 rAbs);

/// @notice Emitted when the result overflows uint256.
error _MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when the input is less than or equal to zero.
error _LogInputTooSmall(uint256 x);

// Lib for fixed-point math in the Dynamic Network Token.
// Thanks to PRBMath.

library DNTfixedPointMath{

// int256s for fixed-point math.

int256 internal constant MAX_SD59x18 = 57896044618658097711785492504343953926634992332820282019728792003956564819967;
int256 internal constant MIN_SD59x18 = - 57896044618658097711785492504343953926634992332820282019728792003956564819968;
int256 internal constant LOG2_E = 1442695040888963407;
int256 internal constant SCALE = 1e18;
int256 internal constant HALF_SCALE = 5e17;

// uint256s for fixed-point math.

uint256 internal constant uSCALE = 1e18;
uint256 internal constant uLOG2_E = 1442695040888963407;
uint256 internal constant uHALF_SCALE = 5e17;

function ln(uint256 x) internal pure returns (uint256 result) {

// Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
// can return is 195205294292027477728.
    unchecked {
        result = (log2(x) * uSCALE) / uLOG2_E;
    }
}

function log2(uint256 x) internal pure returns (uint256 result) {

    if (x <= 0) {
        revert _LogInputTooSmall(x);
    }
        unchecked {
        // This works because log2(x) = -log2(1/x).
        uint256 sign;
        if (x >= uSCALE) {
            sign = 1;
        }
        else {

            // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
        assembly {
            x := div(1000000000000000000000000000000000000, x)
        }
    }

    // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
    uint256 n = mostSignificantBit(uint256(x / uSCALE));

    // The integer part of the logarithm as a signed 59.18-decimal fixed-point number. The operation can't overflow
    // because n is maximum 255, SCALE is 1e18 and sign is either 1 or -1.
    result = uint256(n) * uSCALE;

    // This is y = x * 2^(-n).
    uint256 y = x >> n;

    // If y = 1, the fractional part is zero.
    if (y == uSCALE) {
        return result * sign;
    }

    // Calculate the fractional part via the iterative approximation.
    // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
    for (uint256 delta = uint256(HALF_SCALE); delta > 0; delta >>= 1) {
        y = (y * y) / uSCALE;

    // Is y^2 > 2 and so in the range [2,4)?
        if (y >= 2 * uSCALE) {
    // Add the 2^(-m) factor to the logarithm.
            result += delta;

    // Corresponds to z/2 on Wikipedia.
            y >>= 1;
        }
    }
        result *= sign;
    }
}


/// @notice Finds the zero-based index of the first one in the binary representation of x.
/// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
/// @param x The uint256 number for which to find the index of the most significant bit.
/// @return msb The index of the most significant bit as an uint256.
function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {

    if (x >= 2 ** 128) {
        x >>= 128;
        msb += 128;
    }
    if (x >= 2 ** 64) {
        x >>= 64;
        msb += 64;
    }
    if (x >= 2 ** 32) {
        x >>= 32;
        msb += 32;
    }
    if (x >= 2 ** 16) {
        x >>= 16;
        msb += 16;
    }
    if (x >= 2 ** 8) {
        x >>= 8;
        msb += 8;
    }
    if (x >= 2 ** 4) {
        x >>= 4;
        msb += 4;
    }
    if (x >= 2 ** 2) {
        x >>= 2;
        msb += 2;
    }
    if (x >= 2 ** 1) {
    // No need to shift x any more.
        msb += 1;
    }
}

/// @param x The exponent as a signed 59.18-decimal fixed-point number.
/// @return result The result as a signed 59.18-decimal fixed-point number.

function exp(int256 x) internal pure returns (int256 result) {

    // Without this check, the value passed to "exp2" would be less than -59.794705707972522261.
    if (x < - 41446531673892822322) {
         return 0;
    }

    // Without this check, the value passed to "exp2" would be greater than 192.
    if (x >= 133084258667509499441) {
        revert _ExpInputTooBig(x);
    }

    // Do the fixed-point multiplication inline to save gas.
    unchecked {
        int256 doubleScaleProduct = x * LOG2_E;
        result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
    }
}

/// @param x The exponent as a signed 59.18-decimal fixed-point number.
/// @return result The result as a signed 59.18-decimal fixed-point number.

function exp2(int256 x) internal pure returns (int256 result) {
    // This works because 2^(-x) = 1/2^x.
    if (x < 0) {
    // 2^59.794705707972522262 is the maximum number whose inverse does not truncate down to zero.
        if (x < - 59794705707972522261) {
            return 0;
        }

    // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
        unchecked {
            result = 1e36 / exp2(- x);
        }
    }
    else {
    // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
    if (x >= 192e18) {
        revert _Exp2InputTooBig(x);
    }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x192x64 = (uint256(x) << 64) / uint256(SCALE);
            // Safe to convert the result to int256 directly because the maximum input allowed is 192.
            result = int256(uExp2(x192x64));
        }
    }
}


/// @notice Calculates the binary exponent of x using the binary fraction method.
/// @dev Has to use 192.64-bit fixed-point numbers.
/// See https://ethereum.stackexchange.com/a/96594/24693.
/// @param x The exponent as an unsigned 192.64-bit fixed-point number.
/// @return result The result as an unsigned 60.18-decimal fixed-point number.
function uExp2(uint256 x) internal pure returns (uint256 result) {

    unchecked {
        // Start from 0.5 in the 192.64-bit fixed-point format.
        result = 0x800000000000000000000000000000000000000000000000;

        // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
        // because the initial result is 2^191 and all magic factors are less than 2^65.
        if (x & 0x8000000000000000 > 0) {
            result = (result * 0x16A09E667F3BCC909) >> 64;
        }
        if (x & 0x4000000000000000 > 0) {
            result = (result * 0x1306FE0A31B7152DF) >> 64;
        }
        if (x & 0x2000000000000000 > 0) {
            result = (result * 0x1172B83C7D517ADCE) >> 64;
        }
        if (x & 0x1000000000000000 > 0) {
            result = (result * 0x10B5586CF9890F62A) >> 64;
        }
        if (x & 0x800000000000000 > 0) {
            result = (result * 0x1059B0D31585743AE) >> 64;
        }
        if (x & 0x400000000000000 > 0) {
            result = (result * 0x102C9A3E778060EE7) >> 64;
        }
        if (x & 0x200000000000000 > 0) {
            result = (result * 0x10163DA9FB33356D8) >> 64;
        }
        if (x & 0x100000000000000 > 0) {
            result = (result * 0x100B1AFA5ABCBED61) >> 64;
        }
        if (x & 0x80000000000000 > 0) {
            result = (result * 0x10058C86DA1C09EA2) >> 64;
        }
        if (x & 0x40000000000000 > 0) {
            result = (result * 0x1002C605E2E8CEC50) >> 64;
        }
        if (x & 0x20000000000000 > 0) {
            result = (result * 0x100162F3904051FA1) >> 64;
        }
        if (x & 0x10000000000000 > 0) {
            result = (result * 0x1000B175EFFDC76BA) >> 64;
        }
        if (x & 0x8000000000000 > 0) {
            result = (result * 0x100058BA01FB9F96D) >> 64;
        }
        if (x & 0x4000000000000 > 0) {
            result = (result * 0x10002C5CC37DA9492) >> 64;
        }
        if (x & 0x2000000000000 > 0) {
            result = (result * 0x1000162E525EE0547) >> 64;
        }
        if (x & 0x1000000000000 > 0) {
            result = (result * 0x10000B17255775C04) >> 64;
        }
        if (x & 0x800000000000 > 0) {
            result = (result * 0x1000058B91B5BC9AE) >> 64;
        }
        if (x & 0x400000000000 > 0) {
            result = (result * 0x100002C5C89D5EC6D) >> 64;
        }
        if (x & 0x200000000000 > 0) {
            result = (result * 0x10000162E43F4F831) >> 64;
        }
        if (x & 0x100000000000 > 0) {
            result = (result * 0x100000B1721BCFC9A) >> 64;
        }
        if (x & 0x80000000000 > 0) {
            result = (result * 0x10000058B90CF1E6E) >> 64;
        }
        if (x & 0x40000000000 > 0) {
            result = (result * 0x1000002C5C863B73F) >> 64;
        }
        if (x & 0x20000000000 > 0) {
            result = (result * 0x100000162E430E5A2) >> 64;
        }
        if (x & 0x10000000000 > 0) {
            result = (result * 0x1000000B172183551) >> 64;
        }
        if (x & 0x8000000000 > 0) {
            result = (result * 0x100000058B90C0B49) >> 64;
        }
        if (x & 0x4000000000 > 0) {
            result = (result * 0x10000002C5C8601CC) >> 64;
        }
        if (x & 0x2000000000 > 0) {
            result = (result * 0x1000000162E42FFF0) >> 64;
        }
        if (x & 0x1000000000 > 0) {
            result = (result * 0x10000000B17217FBB) >> 64;
        }
        if (x & 0x800000000 > 0) {
            result = (result * 0x1000000058B90BFCE) >> 64;
        }
        if (x & 0x400000000 > 0) {
            result = (result * 0x100000002C5C85FE3) >> 64;
        }
        if (x & 0x200000000 > 0) {
            result = (result * 0x10000000162E42FF1) >> 64;
        }
        if (x & 0x100000000 > 0) {
            result = (result * 0x100000000B17217F8) >> 64;
        }
        if (x & 0x80000000 > 0) {
            result = (result * 0x10000000058B90BFC) >> 64;
        }
        if (x & 0x40000000 > 0) {
            result = (result * 0x1000000002C5C85FE) >> 64;
        }
        if (x & 0x20000000 > 0) {
            result = (result * 0x100000000162E42FF) >> 64;
        }
        if (x & 0x10000000 > 0) {
            result = (result * 0x1000000000B17217F) >> 64;
        }
        if (x & 0x8000000 > 0) {
            result = (result * 0x100000000058B90C0) >> 64;
        }
        if (x & 0x4000000 > 0) {
            result = (result * 0x10000000002C5C860) >> 64;
        }
        if (x & 0x2000000 > 0) {
            result = (result * 0x1000000000162E430) >> 64;
        }
        if (x & 0x1000000 > 0) {
            result = (result * 0x10000000000B17218) >> 64;
        }
        if (x & 0x800000 > 0) {
            result = (result * 0x1000000000058B90C) >> 64;
        }
        if (x & 0x400000 > 0) {
            result = (result * 0x100000000002C5C86) >> 64;
        }
        if (x & 0x200000 > 0) {
            result = (result * 0x10000000000162E43) >> 64;
        }
        if (x & 0x100000 > 0) {
            result = (result * 0x100000000000B1721) >> 64;
        }
        if (x & 0x80000 > 0) {
            result = (result * 0x10000000000058B91) >> 64;
        }
        if (x & 0x40000 > 0) {
            result = (result * 0x1000000000002C5C8) >> 64;
        }
        if (x & 0x20000 > 0) {
            result = (result * 0x100000000000162E4) >> 64;
        }
        if (x & 0x10000 > 0) {
            result = (result * 0x1000000000000B172) >> 64;
        }
        if (x & 0x8000 > 0) {
            result = (result * 0x100000000000058B9) >> 64;
        }
        if (x & 0x4000 > 0) {
            result = (result * 0x10000000000002C5D) >> 64;
        }
        if (x & 0x2000 > 0) {
            result = (result * 0x1000000000000162E) >> 64;
        }
        if (x & 0x1000 > 0) {
            result = (result * 0x10000000000000B17) >> 64;
        }
        if (x & 0x800 > 0) {
            result = (result * 0x1000000000000058C) >> 64;
        }
        if (x & 0x400 > 0) {
            result = (result * 0x100000000000002C6) >> 64;
        }
        if (x & 0x200 > 0) {
            result = (result * 0x10000000000000163) >> 64;
        }
        if (x & 0x100 > 0) {
            result = (result * 0x100000000000000B1) >> 64;
        }
        if (x & 0x80 > 0) {
            result = (result * 0x10000000000000059) >> 64;
        }
        if (x & 0x40 > 0) {
            result = (result * 0x1000000000000002C) >> 64;
        }
        if (x & 0x20 > 0) {
            result = (result * 0x10000000000000016) >> 64;
        }
        if (x & 0x10 > 0) {
            result = (result * 0x1000000000000000B) >> 64;
        }
        if (x & 0x8 > 0) {
            result = (result * 0x10000000000000006) >> 64;
        }
        if (x & 0x4 > 0) {
            result = (result * 0x10000000000000003) >> 64;
        }
        if (x & 0x2 > 0) {
            result = (result * 0x10000000000000001) >> 64;
        }
        if (x & 0x1 > 0) {
            result = (result * 0x10000000000000001) >> 64;
        }

// We're doing two things at the same time:
//
//   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
//      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
//      rather than 192.
//   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
//
// This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= uSCALE;
            result >>= (191 - (x >> 64));
        }
    }


function div(int256 x, int256 y) internal pure returns (int256 result) {

    if (x == MIN_SD59x18 || y == MIN_SD59x18) {
        revert _DivInputTooSmall();
    }

    // Get hold of the absolute values of x and y.
    uint256 ax;
    uint256 ay;

    unchecked {
        ax = x < 0 ? uint256(- x) : uint256(x);
        ay = y < 0 ? uint256(- y) : uint256(y);
    }

    // Compute the absolute value of (x*SCALE)ÃƒÂ·y. The result must fit within int256.
    uint256 rAbs = mulDiv(ax, uint256(SCALE), ay);
    if (rAbs > uint256(MAX_SD59x18)) {
        revert _DivOverflow(rAbs);
    }

    // Get the signs of x and y.
    uint256 sx;
    uint256 sy;

    assembly {
        sx := sgt(x, sub(0, 1))
        sy := sgt(y, sub(0, 1))
    }

        // XOR over sx and sy. This is basically checking whether the inputs have the same sign. If yes, the result
        // should be positive. Otherwise, it should be negative.
        result = sx ^ sy == 1 ? - int256(rAbs) : int256(rAbs);
    }


/// @param x The multiplicand as an uint256.
/// @param y The multiplier as an uint256.
/// @param denominator The divisor as an uint256.
/// @return result The result as an uint256.

function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {

    // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
    // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
    // variables such that product = prod1 * 2^256 + prod0.
    uint256 prod0; // Least significant 256 bits of the product
    uint256 prod1; // Most significant 256 bits of the product
    assembly {
        let mm := mulmod(x, y, not(0))
        prod0 := mul(x, y)
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    // Handle non-overflow cases, 256 by 256 division.
    if (prod1 == 0) {
        unchecked {
        result = prod0 / denominator;
    }
        return result;
    }

    // Make sure the result is less than 2^256. Also prevents denominator == 0.
    if (prod1 >= denominator) {
        revert _MulDivOverflow(prod1, denominator);
    }

    ///////////////////////////////////////////////
    // 512 by 256 division.
    ///////////////////////////////////////////////

    // Make division exact by subtracting the remainder from [prod1 prod0].
    uint256 remainder;

    assembly {
        // Compute remainder using mulmod.
        remainder := mulmod(x, y, denominator)

        // Subtract 256 bit number from 512 bit number.
        prod1 := sub(prod1, gt(remainder, prod0))
        prod0 := sub(prod0, remainder)
    }

    // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
    // See https://cs.stackexchange.com/q/138556/92363.
    unchecked {
        // Does not overflow because the denominator cannot be zero at this stage in the function.
        uint256 lpotdod = denominator & (~denominator + 1);

    assembly {
            // Divide denominator by lpotdod.
            denominator := div(denominator, lpotdod)

            // Divide [prod1 prod0] by lpotdod.
            prod0 := div(prod0, lpotdod)

            // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
            lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Now use Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

}
