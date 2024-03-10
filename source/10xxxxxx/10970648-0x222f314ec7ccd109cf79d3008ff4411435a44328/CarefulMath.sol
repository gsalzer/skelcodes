pragma solidity ^0.5.16;

import "./BaseReporter.sol";

contract CarefulMath {

    function mulUInt(uint _a, uint _b) internal pure returns (BaseReporter.MathError, uint) {
        if (_a == 0) {
            return (BaseReporter.MathError.NO_ERROR, 0);
        }
        uint c = _a * _b;
        if (c / _a != _b) {
            return (BaseReporter.MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (BaseReporter.MathError.NO_ERROR, c);
        }
    }

    function divUInt(uint _a, uint _b) internal pure returns (BaseReporter.MathError, uint) {
        if (_b == 0) {
            return (BaseReporter.MathError.DIVISION_BY_ZERO, 0);
        }

        return (BaseReporter.MathError.NO_ERROR, _a / _b);
    }

    function subUInt(uint _a, uint _b) internal pure returns (BaseReporter.MathError, uint) {
        if (_b <= _a) {
            return (BaseReporter.MathError.NO_ERROR, _a - _b);
        } else {
            return (BaseReporter.MathError.INTEGER_UNDERFLOW, 0);
        }
    }

    function addUInt(uint _a, uint _b) internal pure returns (BaseReporter.MathError, uint) {
        uint c = _a + _b;
        if (c >= _a) {
            return (BaseReporter.MathError.NO_ERROR, c);
        } else {
            return (BaseReporter.MathError.INTEGER_OVERFLOW, 0);
        }
    }

    function addThenSubUInt(uint _a, uint _b, uint _c) internal pure returns (BaseReporter.MathError, uint) {
        (BaseReporter.MathError err0, uint sum) = addUInt(_a, _b);
        if (err0 != BaseReporter.MathError.NO_ERROR) {
            return (err0, 0);
        }
        return subUInt(sum, _c);
    }
}
