// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <=0.8.0;

/** Taken from the OpenZeppelin github
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);
       
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
    
    function pow(uint256 base, uint256 exponent) internal pure returns (uint256) {
    if (exponent == 0) {
        return 1;
    }
    else if (exponent == 1) {
        return base;
    }
    else if (base == 0 && exponent != 0) {
        return 0;
    }
    else {
        uint256 z = base;
        for (uint256 i = 1; i < exponent; i++)
            z = mul(z, base);
        return z;
    }
}
}
