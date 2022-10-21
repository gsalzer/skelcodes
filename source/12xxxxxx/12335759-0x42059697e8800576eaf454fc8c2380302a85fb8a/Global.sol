// SPDX-License-Identifier: --GRISE--

pragma solidity =0.7.6;

import "./SafeMath.sol";
import "./Interfaces.sol";
import "./Events.sol";

abstract contract Global is Events {

    using SafeMath for uint256;

    struct Globals {
        uint256 totalStaked;
        uint256 totalShares;
        uint256 STShares; // Short Term shares counter
        uint256 MLTShares; // Medium Term and Large Term Shares counter
        uint256 sharePrice;
        uint256 currentGriseDay;
    }

    Globals public globals;

    constructor() {
        globals.sharePrice = 100E15;
    }

    function _increaseGlobals(
        uint8 _stakeType, 
        uint256 _staked,
        uint256 _shares
    )
        internal
    {
        globals.totalStaked =
        globals.totalStaked.add(_staked);

        globals.totalShares =
        globals.totalShares.add(_shares);

        if (_stakeType > 0) {
            globals.MLTShares = 
                globals.MLTShares.add(_shares);
        }else {
            globals.STShares = 
                globals.STShares.add(_shares);
        }

        _logGlobals();
    }

    function _decreaseGlobals(
        uint8 _stakeType,
        uint256 _staked,
        uint256 _shares
    )
        internal
    {
        globals.totalStaked =
        globals.totalStaked > _staked ?
        globals.totalStaked - _staked : 0;

        globals.totalShares =
        globals.totalShares > _shares ?
        globals.totalShares - _shares : 0;

        if (_stakeType > 0) {
            globals.MLTShares = 
                globals.MLTShares > _shares ?
                globals.MLTShares - _shares : 0;
        }else {            
            globals.STShares = 
                globals.STShares > _shares ?
                globals.STShares - _shares : 0;

        }
        
        _logGlobals();
    }

    function _logGlobals()
        private
    {
        emit NewGlobals(
            globals.currentGriseDay,
            globals.totalShares,
            globals.totalStaked,
            globals.STShares,
            globals.MLTShares,
            globals.sharePrice
        );
    }
}
