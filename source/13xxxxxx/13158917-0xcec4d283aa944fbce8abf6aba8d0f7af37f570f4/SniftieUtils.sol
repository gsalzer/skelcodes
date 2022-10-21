// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @dev reusable utility functions
 */
library SniftieUtils {
    /**
     * @dev checks if string where contains string what
     */
    function stringContains(string memory what, string memory where) internal pure returns (bool) {
        bytes memory whatBytes = bytes(what);
        bytes memory whereBytes = bytes(where);

        bool found = false;
        for (uint i = 0; i < whereBytes.length - whatBytes.length; i++) {
            bool flag = true;
            for (uint j = 0; j < whatBytes.length; j++)
                if (whereBytes [i + j] != whatBytes [j]) {
                    flag = false;
                    break;
                }
            if (flag) {
                found = true;
                break;
            }
        }

        return found;
    }
}

