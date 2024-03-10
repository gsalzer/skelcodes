pragma solidity ^0.5.0;


/**
 * @title Math utils
 * @author dicether
 */
library MathUtil {
    /**
     * @dev Returns the absolute value of _val.
     * @param _val value
     * @return The absolute value of _val.
     */
    function abs(int _val) internal pure returns(uint) {
        if (_val < 0) {
            return uint(-_val);
        } else {
            return uint(_val);
        }
    }

    /**
     * @dev Calculate maximum.
     */
    function max(uint _val1, uint _val2) internal pure returns(uint) {
        return _val1 >= _val2 ? _val1 : _val2;
    }

    /**
     * @dev Calculate minimum.
     */
    function min(uint _val1, uint _val2) internal pure returns(uint) {
        return _val1 <= _val2 ? _val1 : _val2;
    }
}

