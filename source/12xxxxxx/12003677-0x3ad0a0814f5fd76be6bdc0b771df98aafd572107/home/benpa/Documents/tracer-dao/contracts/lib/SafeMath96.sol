//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0;

library SafeMath96 {
    function add96(uint96 a, uint96 b) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, "SafeMath96: addition overflow");
        return c;
    }

    function sub96(uint96 a, uint96 b) internal pure returns (uint96) {
        require(b <= a, "SafeMath96: subtraction overflow");
        return a - b;
    }

    function mul96(uint96 a, uint96 b) internal pure returns (uint96) {
        if (a == 0) {
            return 0;
        }

        uint96 c = a * b;
        require(c / a == b, "SafeMath96: multiplication overflow");
        return c;
    }
}

