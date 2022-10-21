// SPDX-License-Identifier: --GRISE--

pragma solidity =0.7.6;

import "./Timing.sol";

abstract contract Utils is Timing {

    using SafeMath for uint256;

    function toUint256(bytes memory _bytes)   
    internal
    pure
    returns (uint256 value) {

    assembly {
      value := mload(add(_bytes, 0x20))
    }
    }

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
    
    function _notFuture(uint256 _day) internal view returns (bool) {
        return _day <= _currentGriseDay();
    }

    function _notPast(uint256 _day) internal view returns (bool) {
        return _day >= _currentGriseDay();
    }

    function _nonZeroAddress(address _address) internal pure returns (bool) {
        return _address != address(0x0);
    }

    function _calculateSellTranscFee(uint256 _tAmount) internal pure returns (uint256) {
        return _tAmount.mul(SELL_TRANS_FEE).div(REWARD_PRECISION_RATE);
    }

    function _calculateBuyTranscFee(uint256 _tAmount) internal pure returns (uint256) {
        return _tAmount.mul(BUY_TRANS_FEE).div(REWARD_PRECISION_RATE);
    }
    
    function calculateGriseWeek(uint256 _day) internal pure returns (uint256) {
        return (_day / GRISE_WEEK);
    }
}
