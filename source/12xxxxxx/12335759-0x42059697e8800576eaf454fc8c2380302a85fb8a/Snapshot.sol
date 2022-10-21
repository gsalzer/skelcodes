// SPDX-License-Identifier: --GRISE--

pragma solidity =0.7.6;

import "./Helper.sol";

abstract contract Snapshot is Helper {

    using SafeMath for uint;

    // regular shares
    struct SnapShot {
        uint256 totalShares;
        uint256 inflationAmount;
        uint256 scheduledToEnd;
    }

    mapping(uint256 => SnapShot) public snapshots;
    
    modifier snapshotTrigger() {
        _dailySnapshotPoint(currentGriseDay());
        _;
    }

    
    /**
     * @notice allows volunteer to offload snapshots
     * to save on gas during next start/end stake
     */
    function manualDailySnapshot()
        external
    {
        _dailySnapshotPoint(currentGriseDay());
    }

    /**
     * @notice allows volunteer to offload snapshots
     * to save on gas during next start/end stake
     * in case manualDailySnapshot reach block limit
     */
    function manualDailySnapshotPoint(
        uint256 _updateDay
    )
        external
    {
        require(
            _updateDay > 0 &&
            _updateDay < currentGriseDay(),
            'GRISE: snapshot day does not exist yet'
        );

        require(
            _updateDay > globals.currentGriseDay,
            'GRISE: snapshot already taken for that day'
        );

        _dailySnapshotPoint(_updateDay);
    }

    /**
     * @notice internal function that offloads
     * global values to daily snapshots
     * updates globals.currentGriseDay
     */
    function _dailySnapshotPoint(
        uint256 _updateDay
    )
        private
    {
    
        uint256 scheduledToEndToday;
        uint256 totalStakedToday = globals.totalStaked;

        for (uint256 _day = globals.currentGriseDay; _day < _updateDay; _day++) {

            // ------------------------------------
            // prepare snapshot for regular shares
            // reusing scheduledToEndToday variable

            scheduledToEndToday = scheduledToEnd[_day] + snapshots[_day - 1].scheduledToEnd;

            SnapShot memory snapshot = snapshots[_day];
            snapshot.scheduledToEnd = scheduledToEndToday;

            snapshot.totalShares =
                globals.totalShares > scheduledToEndToday ?
                globals.totalShares - scheduledToEndToday : 0;

            snapshot.inflationAmount =  snapshot.totalShares
                .mul(PRECISION_RATE)
                .div(
                    _inflationAmount(
                        totalStakedToday,
                        GRISE_CONTRACT.totalSupply(),
                        INFLATION_RATE
                    )
                );

            // store regular snapshot
            snapshots[_day] = snapshot;
            globals.currentGriseDay++;
        }
    }

    function _inflationAmount(uint256 _totalStaked, uint256 _totalSupply, uint256 _INFLATION_RATE) private pure returns (uint256) {
        return (_totalStaked + _totalSupply) * 10000 / _INFLATION_RATE;
    }
}
