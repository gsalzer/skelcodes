pragma solidity ^0.8.0; 

/*
 SPDX-License-Identifier: MIT
*/

/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, 'SafeMath mul failed');
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SafeMath div failed');
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, 'SafeMath sub failed');
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath add failed');
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }    
}
