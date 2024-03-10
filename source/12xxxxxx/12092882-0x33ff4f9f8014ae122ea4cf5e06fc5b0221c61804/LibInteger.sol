pragma solidity 0.5.10;

/**
 * @title LibInteger 
 * @dev Integer related utility functions
 */
library LibInteger
{    
    /**
     * @dev Safely multiply, revert on overflow
     * @param a The first number
     * @param b The second number
     * @return uint The answer
    */
    function mul(uint a, uint b) internal pure returns (uint)
    {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Safely divide, revert if divisor is zero
     * @param a The first number
     * @param b The second number
     * @return uint The answer
    */
    function div(uint a, uint b) internal pure returns (uint)
    {
        require(b > 0, "");
        uint c = a / b;

        return c;
    }

    /**
     * @dev Safely substract, revert if answer is negative
     * @param a The first number
     * @param b The second number
     * @return uint The answer
    */
    function sub(uint a, uint b) internal pure returns (uint)
    {
        require(b <= a, "");
        uint c = a - b;

        return c;
    }

    /**
     * @dev Safely add, revert if overflow
     * @param a The first number
     * @param b The second number
     * @return uint The answer
    */
    function add(uint a, uint b) internal pure returns (uint)
    {
        uint c = a + b;
        require(c >= a, "");

        return c;
    }

    /**
     * @dev Convert number to string
     * @param value The number to convert
     * @return string The string representation
    */
    function toString(uint value) internal pure returns (string memory)
    {
        if (value == 0) {
            return "0";
        }

        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);
        uint index = digits - 1;
        
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        
        return string(buffer);
    }
}

