// SPDX-License-Identifier: --GRISE--

pragma solidity =0.7.6;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'GRISE: SafeMath Add failed');
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, 'GRISE: SafeMath Sub failed');
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0 || b == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'GRISE: SafeMath Mul failed');
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        
        if (b == 0) {
            return 0;
        }

        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, 'GRISE: SafeMath Mod failed');
        return a % b;
    }
}

