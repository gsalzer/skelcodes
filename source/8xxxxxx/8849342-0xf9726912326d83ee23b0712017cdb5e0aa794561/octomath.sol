pragma solidity ^0.5.0;

import "./safemath.sol";

library octomath
{
    using SafeMath for uint256;

    /**
    * @dev Ceiling of integer division of two unsigned integers, reverts on division by zero.
    */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "Can't divide by 0");
        uint256 c = a.add(b).sub(1).div(b);
        return c;
    }
}
