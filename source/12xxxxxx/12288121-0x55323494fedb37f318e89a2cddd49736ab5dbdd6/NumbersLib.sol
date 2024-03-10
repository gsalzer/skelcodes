// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";

/**
 * @dev Utility library for uint256 numbers
 */
library NumbersLib {
    using SafeMath for uint256;

    /**
        @dev It represents 100% with 2 decimal places.
     */
    function ONE_HUNDRED_PERCENT() internal pure returns (uint256) {
        return 10000;
    }

    /**
        @notice Returns the positive difference value of a number to another number
        @param self The number to return the difference value for
        @param other The other number to calucualte the difference against
        @return uint256 The difference value
     */
    function diff(uint256 self, uint256 other) internal pure returns (uint256) {
        return other > self ? other.sub(self) : self.sub(other);
    }

    /**
        @notice Returns the positive percentage difference of a value to 100%
        @param self The number to return the percentage difference for
        @return uint256 The percentage difference value
     */
    function diffOneHundredPercent(uint256 self)
        internal
        pure
        returns (uint256)
    {
        return diff(self, ONE_HUNDRED_PERCENT());
    }

    /**
     * @notice Returns a percentage value of a number.
     * @param self The number to get a percentage of.
     * @param percentage The percentage value to calculate with 2 decimal places (10000 = 100%).
     */
    function percent(uint256 self, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        return self.mul(percentage).div(ONE_HUNDRED_PERCENT());
    }

    function percent(int256 self, uint256 percentage)
        internal
        pure
        returns (int256)
    {
        return (self * int256(percentage)) / int256(ONE_HUNDRED_PERCENT());
    }

    function abs(int256 self) internal pure returns (uint256) {
        return self >= 0 ? uint256(self) : uint256(-1 * self);
    }

    /**
     * @notice Returns a ratio of 2 numbers.
     * @param self The number to get a ratio of.
     * @param num The number to calculate the ratio for.
     * @return Ratio of 2 numbers with 2 decimal places (10000 = 100%).
     */
    function ratioOf(uint256 self, uint256 num)
        internal
        pure
        returns (uint256)
    {
        return self.mul(ONE_HUNDRED_PERCENT()).div(num);
    }
}

