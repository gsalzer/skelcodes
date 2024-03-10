// SPDX-License-Identifier: --GRISE--

pragma solidity =0.7.6;

import "./Declaration.sol";

abstract contract Helper is Declaration {

    using SafeMath for uint256;

    function notContract(address _addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size == 0);
    }

    function toBytes16(uint256 x) internal pure returns (bytes16 b) {
       return bytes16(bytes32(x));
    }

    function generateID(address x, uint256 y, bytes1 z) public pure returns (bytes16 b) {
        b = toBytes16(
            uint256(
                keccak256(
                    abi.encodePacked(x, y, z)
                )
            )
        );
    }

    function generateStakeID(address _staker) internal view returns (bytes16 stakeID) {
        return generateID(_staker, stakeCount[_staker], 0x01);
    }

    function currentGriseDay() internal view returns (uint256) {
        return GRISE_CONTRACT.currentGriseDay();
    }

    function latestStakeID(address _staker) external view returns (bytes16) {
        return stakeCount[_staker] == 0 ? bytes16(0) : generateID(_staker, stakeCount[_staker].sub(1), 0x01);
    }

    function _increaseStakeCount(address _staker) internal {
        stakeCount[_staker] = stakeCount[_staker] + 1;
    }

    function _isMatureStake(Stake memory _stake) internal view returns (bool) {
        return _stake.closeDay > 0
            ? _stake.finalDay <= _stake.closeDay
            : _stake.finalDay <= currentGriseDay();
    }

    function _stakeNotStarted(Stake memory _stake) internal view returns (bool) {
        return _stake.closeDay > 0
            ? _stake.startDay > _stake.closeDay
            : _stake.startDay > currentGriseDay();
    }

    function _stakeEligibleForWeeklyReward(Stake memory _stake) internal view returns (bool) {
        uint256 curGriseDay = currentGriseDay();
        
        return ( _stake.isActive && 
                !_stakeNotStarted(_stake) &&
                (_startingDay(_stake) < curGriseDay.sub(curGriseDay.mod(GRISE_WEEK)) ||
                   curGriseDay >= _stake.finalDay));
    }

    function _stakeEligibleForMonthlyReward(Stake memory _stake) internal view returns (bool) {
        uint256 curGriseDay = currentGriseDay();

        return ( _stake.isActive && 
                !_stakeNotStarted(_stake) &&
                (_startingDay(_stake) < curGriseDay.sub(curGriseDay.mod(GRISE_MONTH)) ||
                   curGriseDay >= _stake.finalDay));
    }

    function _stakeEnded(Stake memory _stake) internal view returns (bool) {
        return _stake.isActive == false || _isMatureStake(_stake);
    }

    function _daysLeft(Stake memory _stake) internal view returns (uint256) {
        return _stake.isActive == false
            ? _daysDiff(_stake.closeDay, _stake.finalDay)
            : _daysDiff(currentGriseDay(), _stake.finalDay);
    }

    function _daysDiff(uint256 _startDate, uint256 _endDate) internal pure returns (uint256) {
        return _startDate > _endDate ? 0 : _endDate.sub(_startDate);
    }

    function _calculationDay(Stake memory _stake) internal view returns (uint256) {
        return _stake.finalDay > globals.currentGriseDay ? globals.currentGriseDay : _stake.finalDay;
    }

    function _startingDay(Stake memory _stake) internal pure returns (uint256) {
        return _stake.scrapeDay == 0 ? _stake.startDay : _stake.scrapeDay;
    }

    function _notFuture(uint256 _day) internal view returns (bool) {
        return _day <= currentGriseDay();
    }

    function _notPast(uint256 _day) internal view returns (bool) {
        return _day >= currentGriseDay();
    }

    function _nonZeroAddress(address _address) internal pure returns (bool) {
        return _address != address(0x0);
    }

    function _getLockDays(Stake memory _stake) internal pure returns (uint256) {
        return
            _stake.lockDays > 1 ?
            _stake.lockDays - 1 : 1;
    }

    function stakesPagination(
        address _staker,
        uint256 _offset,
        uint256 _length
    )
        external
        view
        returns (bytes16[] memory _stakes)
    {
        uint256 start = _offset > 0 &&
            stakeCount[_staker] > _offset ?
            stakeCount[_staker] - _offset : stakeCount[_staker];

        uint256 finish = _length > 0 &&
            start > _length ?
            start - _length : 0;

        uint256 i;

        _stakes = new bytes16[](start - finish);

        for (uint256 _stakeIndex = start; _stakeIndex > finish; _stakeIndex--) {
            bytes16 _stakeID = generateID(_staker, _stakeIndex - 1, 0x01);
            if (stakes[_staker][_stakeID].stakedAmount > 0) {
                _stakes[i] = _stakeID; i++;
            }
        }
    }
    
}
