// SPDX-License-Identifier: MIT
pragma solidity =0.7.5;


import "LibSafeMath.sol";
import "LibBaseAuth.sol";


/**
 * @dev Burning.
 */
contract Burning is BaseAuth {
    using SafeMath for uint256;

    uint16 private _burningPermilleMin;
    uint16 private _burningPermilleMax;
    uint16 private _burningPermilleMod;

    constructor () {
        _burningPermilleMin = 10;
        _burningPermilleMax = 30;
        _burningPermilleMod = 21;
    }

    /**
     * @dev Sets the burning border from `min` and `max`.
     */
    function setBurningBorder(
        uint16 min,
        uint16 max
    )
        external
        onlyAgent
    {
        require(min <= 1000, "Set burning border: min exceeds 100.0%");
        require(max <= 1000, "Set burning border: max exceeds 100.0%");
        require(min <= max, 'Set burning border: min exceeds max');

        _burningPermilleMin = min;
        _burningPermilleMax = max;
        _burningPermilleMod = _burningPermilleMax - _burningPermilleMin + 1;
    }

    /**
     * @dev Returns the min/max value of burning permille.
     */
    function burningPermilleBorder()
        public
        view
        returns (uint16 min, uint16 max)
    {
        min = _burningPermilleMin;
        max = _burningPermilleMax;
    }

    /**
     * @dev Returns {value} of burning permille.
     */
    function burningPermille()
        public
        view
        returns (uint16)
    {
        if (_burningPermilleMax == 0)
            return 0;

        if (_burningPermilleMin == _burningPermilleMax)
            return _burningPermilleMin;

        return uint16(uint256(keccak256(abi.encode(blockhash(block.number - 1)))).mod(_burningPermilleMod).add(_burningPermilleMin));
    }
}

