pragma solidity ^0.6.12;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a, 'SafeMath:INVALID_ADD');
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a, 'SafeMath:OVERFLOW_SUB');
        c = a - b;
    }

    function mul(uint a, uint b, uint decimal) internal pure returns (uint) {
        uint dc = 10**decimal;
        uint c0 = a * b;
        require(a == 0 || c0 / a == b, "SafeMath: multiple overflow");
        uint c1 = c0 + (dc / 2);
        require(c1 >= c0, "SafeMath: multiple overflow");
        uint c2 = c1 / dc;
        return c2;
    }

    function div(uint256 a, uint256 b, uint decimal) internal pure returns (uint256) {
        require(b != 0, "SafeMath: division by zero");
        uint dc = 10**decimal;
        uint c0 = a * dc;
        require(a == 0 || c0 / a == dc, "SafeMath: division internal");
        uint c1 = c0 + (b / 2);
        require(c1 >= c0, "SafeMath: division internal");
        uint c2 = c1 / b;
        return c2;
    }
}

