pragma solidity ^0.5.7;

contract LibMath {
    // Copied from openzeppelin Math
    /**
    * @dev Returns the largest of two numbers.
    */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
    * @dev Returns the smallest of two numbers.
    */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
    * @dev Calculates the average of two numbers. Since these are integers,
    * averages of an even and odd number cannot be represented, and will be
    * rounded down.
    */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    // Modified from openzeppelin SafeMath
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }

    // Copied from 0x LibMath
    /*
      Copyright 2018 ZeroEx Intl.
      Licensed under the Apache License, Version 2.0 (the "License");
      you may not use this file except in compliance with the License.
      You may obtain a copy of the License at
        http://www.apache.org/licenses/LICENSE-2.0
      Unless required by applicable law or agreed to in writing, software
      distributed under the License is distributed on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
      See the License for the specific language governing permissions and
      limitations under the License.
    */
    /// @dev Calculates partial value given a numerator and denominator rounded down.
    ///      Reverts if rounding error is >= 0.1%
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return Partial value of target rounded down.
    function safeGetPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
    internal
    pure
    returns (uint256 partialAmount)
    {
        require(
            denominator > 0,
            "DIVISION_BY_ZERO"
        );

        require(
            !isRoundingErrorFloor(
            numerator,
            denominator,
            target
        ),
            "ROUNDING_ERROR"
        );

        partialAmount = div(
            mul(numerator, target),
            denominator
        );
        return partialAmount;
    }

    /// @dev Calculates partial value given a numerator and denominator rounded down.
    ///      Reverts if rounding error is >= 0.1%
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return Partial value of target rounded up.
    function safeGetPartialAmountCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
    internal
    pure
    returns (uint256 partialAmount)
    {
        require(
            denominator > 0,
            "DIVISION_BY_ZERO"
        );

        require(
            !isRoundingErrorCeil(
            numerator,
            denominator,
            target
        ),
            "ROUNDING_ERROR"
        );

        partialAmount = div(
            add(
                mul(numerator, target),
                sub(denominator, 1)
            ),
            denominator
        );
        return partialAmount;
    }

    /// @dev Calculates partial value given a numerator and denominator rounded down.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return Partial value of target rounded down.
    function getPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
    internal
    pure
    returns (uint256 partialAmount)
    {
        require(
            denominator > 0,
            "DIVISION_BY_ZERO"
        );

        partialAmount = div(
            mul(numerator, target),
            denominator
        );
        return partialAmount;
    }

    /// @dev Calculates partial value given a numerator and denominator rounded down.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return Partial value of target rounded up.
    function getPartialAmountCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
    internal
    pure
    returns (uint256 partialAmount)
    {
        require(
            denominator > 0,
            "DIVISION_BY_ZERO"
        );

        partialAmount = div(
            add(
                mul(numerator, target),
                sub(denominator, 1)
            ),
            denominator
        );
        return partialAmount;
    }

    /// @dev Checks if rounding error >= 0.1% when rounding down.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return Rounding error is present.
    function isRoundingErrorFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
    internal
    pure
    returns (bool isError)
    {
        require(
            denominator > 0,
            "DIVISION_BY_ZERO"
        );

        // The absolute rounding error is the difference between the rounded
        // value and the ideal value. The relative rounding error is the
        // absolute rounding error divided by the absolute value of the
        // ideal value. This is undefined when the ideal value is zero.
        //
        // The ideal value is `numerator * target / denominator`.
        // Let's call `numerator * target % denominator` the remainder.
        // The absolute error is `remainder / denominator`.
        //
        // When the ideal value is zero, we require the absolute error to
        // be zero. Fortunately, this is always the case. The ideal value is
        // zero iff `numerator == 0` and/or `target == 0`. In this case the
        // remainder and absolute error are also zero.
        if (target == 0 || numerator == 0) {
            return false;
        }

        // Otherwise, we want the relative rounding error to be strictly
        // less than 0.1%.
        // The relative error is `remainder / (numerator * target)`.
        // We want the relative error less than 1 / 1000:
        //        remainder / (numerator * denominator)  <  1 / 1000
        // or equivalently:
        //        1000 * remainder  <  numerator * target
        // so we have a rounding error iff:
        //        1000 * remainder  >=  numerator * target
        uint256 remainder = mulmod(
            target,
            numerator,
            denominator
        );
        isError = mul(1000, remainder) >= mul(numerator, target);
        return isError;
    }

    /// @dev Checks if rounding error >= 0.1% when rounding up.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return Rounding error is present.
    function isRoundingErrorCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
    internal
    pure
    returns (bool isError)
    {
        require(
            denominator > 0,
            "DIVISION_BY_ZERO"
        );

        // See the comments in `isRoundingError`.
        if (target == 0 || numerator == 0) {
            // When either is zero, the ideal value and rounded value are zero
            // and there is no rounding error. (Although the relative error
            // is undefined.)
            return false;
        }
        // Compute remainder as before
        uint256 remainder = mulmod(
            target,
            numerator,
            denominator
        );
        remainder = sub(denominator, remainder) % denominator;
        isError = mul(1000, remainder) >= mul(numerator, target);
        return isError;
    }
}
