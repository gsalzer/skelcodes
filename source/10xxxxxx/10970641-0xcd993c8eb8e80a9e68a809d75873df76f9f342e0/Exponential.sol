pragma solidity ^0.5.16;

import "./AegisMath.sol";
import "./BaseReporter.sol";
import "./CarefulMath.sol";

contract Exponential is CarefulMath {

    uint constant expScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    struct Double {
        uint mantissa;
    }

    /**
     * @notice Creates an exponential from numerator and denominator values
     * @param _num uint
     * @param _denom uint
     * @return MathError, Exp
     */
    function getExp(uint _num, uint _denom) pure internal returns (BaseReporter.MathError, Exp memory) {
        (BaseReporter.MathError err0, uint scaledNumerator) = mulUInt(_num, expScale);
        if (err0 != BaseReporter.MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        (BaseReporter.MathError err1, uint rational) = divUInt(scaledNumerator, _denom);
        if (err1 != BaseReporter.MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }
        return (BaseReporter.MathError.NO_ERROR, Exp({mantissa: rational}));
    }

    /**
     * @notice Adds two exponentials, returning a new exponential
     * @param _a exp
     * @param _b exp
     * @return MathError, Exp
     */
    function addExp(Exp memory _a, Exp memory _b) pure internal returns (BaseReporter.MathError, Exp memory) {
        (BaseReporter.MathError error, uint result) = addUInt(_a.mantissa, _b.mantissa);
        return (error, Exp({mantissa: result}));
    }

    /**
     * @notice Subtracts two exponentials, returning a new exponential
     * @param _a exp
     * @param _b exp
     * @return MathError, Exp
     */
    function subExp(Exp memory _a, Exp memory _b) pure internal returns (BaseReporter.MathError, Exp memory) {
        (BaseReporter.MathError error, uint result) = subUInt(_a.mantissa, _b.mantissa);
        return (error, Exp({mantissa: result}));
    }

    /**
     * @notice Multiply an Exp by a scalar, returning a new Exp
     * @param _a exp
     * @param _scalar uint
     * @return MathError, Exp
     */
    function mulScalar(Exp memory _a, uint _scalar) pure internal returns (BaseReporter.MathError, Exp memory) {
        (BaseReporter.MathError err0, uint scaledMantissa) = mulUInt(_a.mantissa, _scalar);
        if (err0 != BaseReporter.MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return (BaseReporter.MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
    }

    /**
     * @notice Multiply an Exp by a scalar, then truncate to return an unsigned integer
     * @param _a exp
     * @param _scalar uint
     * @return MathError, Exp
     */
    function mulScalarTruncate(Exp memory _a, uint _scalar) pure internal returns (BaseReporter.MathError, uint) {
        (BaseReporter.MathError err, Exp memory product) = mulScalar(_a, _scalar);
        if (err != BaseReporter.MathError.NO_ERROR) {
            return (err, 0);
        }
        return (BaseReporter.MathError.NO_ERROR, truncate(product));
    }

    /**
     * @notice Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer
     * @param _a exp
     * @param _scalar uint
     * @param _addend uint
     * @return MathError, Exp
     */
    function mulScalarTruncateAddUInt(Exp memory _a, uint _scalar, uint _addend) pure internal returns (BaseReporter.MathError, uint) {
        (BaseReporter.MathError err, Exp memory product) = mulScalar(_a, _scalar);
        if (err != BaseReporter.MathError.NO_ERROR) {
            return (err, 0);
        }
        return addUInt(truncate(product), _addend);
    }

    /**
     * @notice Divide an Exp by a scalar, returning a new Exp
     * @param _a exp
     * @param _scalar uint
     * @return MathError, Exp
     */
    function divScalar(Exp memory _a, uint _scalar) pure internal returns (BaseReporter.MathError, Exp memory) {
        (BaseReporter.MathError err0, uint descaledMantissa) = divUInt(_a.mantissa, _scalar);
        if (err0 != BaseReporter.MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return (BaseReporter.MathError.NO_ERROR, Exp({mantissa: descaledMantissa}));
    }

    /**
     * @notice Divide a scalar by an Exp, returning a new Exp
     * @param _scalar uint
     * @param _divisor exp
     * @return MathError, Exp
     */
    function divScalarByExp(uint _scalar, Exp memory _divisor) pure internal returns (BaseReporter.MathError, Exp memory) {
        (BaseReporter.MathError err0, uint numerator) = mulUInt(expScale, _scalar);
        if (err0 != BaseReporter.MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return getExp(numerator, _divisor.mantissa);
    }

    /**
     * @notice Divide a scalar by an Exp, then truncate to return an unsigned integer
     * @param _scalar uint
     * @param _divisor exp
     * @return MathError, Exp
     */
    function divScalarByExpTruncate(uint _scalar, Exp memory _divisor) pure internal returns (BaseReporter.MathError, uint) {
        (BaseReporter.MathError err, Exp memory fraction) = divScalarByExp(_scalar, _divisor);
        if (err != BaseReporter.MathError.NO_ERROR) {
            return (err, 0);
        }
        return (BaseReporter.MathError.NO_ERROR, truncate(fraction));
    }

    /**
     * @notice Multiplies two exponentials, returning a new exponential
     * @param _a exp
     * @param _b exp
     * @return MathError, Exp
     */
    function mulExp(Exp memory _a, Exp memory _b) pure internal returns (BaseReporter.MathError, Exp memory) {
        (BaseReporter.MathError err0, uint doubleScaledProduct) = mulUInt(_a.mantissa, _b.mantissa);
        if (err0 != BaseReporter.MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        (BaseReporter.MathError err1, uint doubleScaledProductWithHalfScale) = addUInt(halfExpScale, doubleScaledProduct);
        if (err1 != BaseReporter.MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }
        (BaseReporter.MathError err2, uint product) = divUInt(doubleScaledProductWithHalfScale, expScale);
        assert(err2 == BaseReporter.MathError.NO_ERROR);
        return (BaseReporter.MathError.NO_ERROR, Exp({mantissa: product}));
    }

    /**
     * @notice Multiplies two exponentials given their mantissas, returning a new exponential
     * @param _a uint
     * @param _b uint
     * @return MathError, Exp
     */
    function mulExp(uint _a, uint _b) pure internal returns (BaseReporter.MathError, Exp memory) {
        return mulExp(Exp({mantissa: _a}), Exp({mantissa: _b}));
    }

    /**
     * @notice Multiplies three exponentials, returning a new exponential.
     * @param _a exp
     * @param _b exp
     * @param _c exp
     * @return MathError, Exp
     */
    function mulExp3(Exp memory _a, Exp memory _b, Exp memory _c) pure internal returns (BaseReporter.MathError, Exp memory) {
        (BaseReporter.MathError err, Exp memory ab) = mulExp(_a, _b);
        if (err != BaseReporter.MathError.NO_ERROR) {
            return (err, ab);
        }
        return mulExp(ab, _c);
    }

    /**
     * @notice Divides two exponentials, returning a new exponential
     * @param _a exp
     * @param _b exp
     * @return MathError, Exp
     */
    function divExp(Exp memory _a, Exp memory _b) pure internal returns (BaseReporter.MathError, Exp memory) {
        return getExp(_a.mantissa, _b.mantissa);
    }

    /**
     * @notice Truncates the given exp to a whole number value
     * @param _exp exp
     * @return uint
     */
    function truncate(Exp memory _exp) pure internal returns (uint) {
        return _exp.mantissa / expScale;
    }

    /**
     * @notice Checks if first Exp is less than second Exp
     * @param _left exp
     * @param _right exp
     * @return bool
     */
    function lessThanExp(Exp memory _left, Exp memory _right) pure internal returns (bool) {
        return _left.mantissa < _right.mantissa;
    }

    /**
     * @notice Checks if left Exp <= right Exp
     * @param _left exp
     * @param _right exp
     * @return bool
     */
    function lessThanOrEqualExp(Exp memory _left, Exp memory _right) pure internal returns (bool) {
        return _left.mantissa <= _right.mantissa;
    }

    /**
     * @notice Checks if left Exp > right Exp.
     * @param _left exp
     * @param _right exp
     */
    function greaterThanExp(Exp memory _left, Exp memory _right) pure internal returns (bool) {
        return _left.mantissa > _right.mantissa;
    }

    /**
     * @notice returns true if Exp is exactly zero
     * @param _value exp
     * @return MathError, Exp
     */
    function isZeroExp(Exp memory _value) pure internal returns (bool) {
        return _value.mantissa == 0;
    }

    function safe224(uint _n, string memory _errorMessage) pure internal returns (uint224) {
        require(_n < 2**224, _errorMessage);
        return uint224(_n);
    }

    function safe32(uint _n, string memory _errorMessage) pure internal returns (uint32) {
        require(_n < 2**32, _errorMessage);
        return uint32(_n);
    }

    function add_(Exp memory _a, Exp memory _b) pure internal returns (Exp memory) {
        return Exp({mantissa: add_(_a.mantissa, _b.mantissa)});
    }

    function add_(Double memory _a, Double memory _b) pure internal returns (Double memory) {
        return Double({mantissa: add_(_a.mantissa, _b.mantissa)});
    }

    function add_(uint _a, uint _b) pure internal returns (uint) {
        return add_(_a, _b, "add overflow");
    }

    function add_(uint _a, uint _b, string memory _errorMessage) pure internal returns (uint) {
        uint c = _a + _b;
        require(c >= _a, _errorMessage);
        return c;
    }

    function sub_(Exp memory _a, Exp memory _b) pure internal returns (Exp memory) {
        return Exp({mantissa: sub_(_a.mantissa, _b.mantissa)});
    }

    function sub_(Double memory _a, Double memory _b) pure internal returns (Double memory) {
        return Double({mantissa: sub_(_a.mantissa, _b.mantissa)});
    }

    function sub_(uint _a, uint _b) pure internal returns (uint) {
        return sub_(_a, _b, "sub underflow");
    }

    function sub_(uint _a, uint _b, string memory _errorMessage) pure internal returns (uint) {
        require(_b <= _a, _errorMessage);
        return _a - _b;
    }

    function mul_(Exp memory _a, Exp memory _b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(_a.mantissa, _b.mantissa) / expScale});
    }

    function mul_(Exp memory _a, uint _b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(_a.mantissa, _b)});
    }

    function mul_(uint _a, Exp memory _b) pure internal returns (uint) {
        return mul_(_a, _b.mantissa) / expScale;
    }

    function mul_(Double memory _a, Double memory _b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(_a.mantissa, _b.mantissa) / doubleScale});
    }

    function mul_(Double memory _a, uint _b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(_a.mantissa, _b)});
    }

    function mul_(uint _a, Double memory _b) pure internal returns (uint) {
        return mul_(_a, _b.mantissa) / doubleScale;
    }

    function mul_(uint _a, uint _b) pure internal returns (uint) {
        return mul_(_a, _b, "mul overflow");
    }

    function mul_(uint _a, uint _b, string memory _errorMessage) pure internal returns (uint) {
        if (_a == 0 || _b == 0) {
            return 0;
        }
        uint c = _a * _b;
        require(c / _a == _b, _errorMessage);
        return c;
    }

    function div_(Exp memory _a, Exp memory _b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(mul_(_a.mantissa, expScale), _b.mantissa)});
    }

    function div_(Exp memory _a, uint _b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(_a.mantissa, _b)});
    }

    function div_(uint _a, Exp memory _b) pure internal returns (uint) {
        return div_(mul_(_a, expScale), _b.mantissa);
    }

    function div_(Double memory _a, Double memory _b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(_a.mantissa, doubleScale), _b.mantissa)});
    }

    function div_(Double memory _a, uint _b) pure internal returns (Double memory) {
        return Double({mantissa: div_(_a.mantissa, _b)});
    }

    function div_(uint _a, Double memory _b) pure internal returns (uint) {
        return div_(mul_(_a, doubleScale), _b.mantissa);
    }

    function div_(uint _a, uint _b) pure internal returns (uint) {
        return div_(_a, _b, "div by zero");
    }

    function div_(uint _a, uint _b, string memory _errorMessage) pure internal returns (uint) {
        require(_b > 0, _errorMessage);
        return _a / _b;
    }

    function fraction(uint _a, uint _b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(_a, doubleScale), _b)});
    }
}
