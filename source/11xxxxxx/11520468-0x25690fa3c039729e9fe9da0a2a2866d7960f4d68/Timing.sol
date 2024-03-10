// SPDX-License-Identifier: --🥺--

pragma solidity =0.7.0;

import "./Declaration.sol";

abstract contract Timing is Declaration {

    function currentTFDay() public view returns (uint64) {
        return _getNow() >= LAUNCH_TIME ? _currentTFDay() : 0;
    }

    function _currentTFDay() internal view returns (uint64) {
        return _tfDayFromStamp(_getNow());
    }

    function _nextTFDay() internal view returns (uint64) {
        return _currentTFDay() + 1;
    }

    function _previousTFDay() internal view returns (uint64) {
        return _currentTFDay() - 1;
    }

    function _tfDayFromStamp(uint256 _timestamp) internal view returns (uint64) {
        return uint64((_timestamp - LAUNCH_TIME) / SECONDS_IN_DAY);
    }

    function _getNow() internal view returns (uint256) {
        return block.timestamp;
    }
}
