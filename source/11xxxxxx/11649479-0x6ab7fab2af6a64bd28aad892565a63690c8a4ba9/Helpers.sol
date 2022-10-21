// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

import './SafeMath.sol';

library Helpers {
    using SafeMath for uint256;

    /**
     * @param number number to get percentage of
     * @param percent percentage (8 decimals)
     * @return The percentage of the number
     */
    function percentageOf(uint256 number, uint256 percent) internal pure returns (uint256) {
        return number.mul(percent).div(100000000);
    }

    /**
     * @param keccak keccak256 hash to use
     * @return The referral code
     */
    function keccak256ToReferralCode(bytes32 keccak) internal pure returns (bytes3) {
        bytes3 code;
        for (uint8 i = 0; i < 3; ++i) {
            code |= bytes3(keccak[i]) >> (i * 8);
        }
        return code;
    }

}
