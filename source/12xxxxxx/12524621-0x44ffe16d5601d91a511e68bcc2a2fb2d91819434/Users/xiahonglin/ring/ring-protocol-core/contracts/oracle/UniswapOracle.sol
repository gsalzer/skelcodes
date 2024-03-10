// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

// Referencing Uniswap Example Simple Oracle
// https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/examples/ExampleOracleSimple.sol

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "./IUniswapOracle.sol";
import "../refs/CoreRef.sol";

/// @title Uniswap Oracle for ETH/USDC
/// @author Ring Protocol
/// @notice maintains the TWAP of a uniswap v3 pool contract over a specified duration
contract UniswapOracle is IUniswapOracle, CoreRef {
    using Decimal for Decimal.D256;

    /// @notice the referenced uniswap pair contract
    IUniswapV3Pool public override pool;
    bool public isPrice0;

    /// @notice the window over which the initial price will "thaw" to the true peg price
    uint32 public override duration;

    uint256 private constant FIXED_POINT_GRANULARITY = 2**96;
    uint256 private constant USDC_DECIMALS_MULTIPLIER = 1e12; // to normalize USDC

    /// @notice UniswapOracle constructor
    /// @param _core Ring Core for reference
    /// @param _pool Uniswap V3 Pool to provide TWAP
    /// @param _duration TWAP duration
    /// @param _isPrice0 flag for using token0 or token1 for cumulative on Uniswap
    constructor(
        address _core,
        address _pool,
        uint32 _duration,
        bool _isPrice0
    ) CoreRef(_core) {
        pool = IUniswapV3Pool(_pool);
        // Relative to USD per ETH price
        isPrice0 = _isPrice0;

        duration = _duration;
    }

    /// @notice read the oracle price
    /// @return oracle price
    /// @return true if price is valid
    /// @dev price is to be denominated in USD per X where X can be ETH, etc.
    function read() external view override returns (Decimal.D256 memory, bool) {
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = duration;
        secondsAgos[1] = 0;
        (int56[] memory tickCumulatives, ) = pool.observe(secondsAgos);

        int56 timeWeightedTick = (tickCumulatives[1] - tickCumulatives[0]) / duration;
        require(timeWeightedTick <= type(int24).max && timeWeightedTick >= type(int24).min);

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(int24(timeWeightedTick));
        bool valid = !(paused() || sqrtPriceX96 == 0);
        Decimal.D256 memory sqrtPriceDecimal;
        if (isPrice0) {
            sqrtPriceDecimal = Decimal.ratio(sqrtPriceX96, FIXED_POINT_GRANULARITY);
        } else {
            sqrtPriceDecimal = Decimal.ratio(FIXED_POINT_GRANULARITY, sqrtPriceX96);
        }
        return (sqrtPriceDecimal.pow(2).mul(USDC_DECIMALS_MULTIPLIER), valid);
    }

    /// @notice set a new duration for the TWAP window
    function setDuration(uint32 _duration) external override onlyGovernor {
        duration = _duration;
        emit DurationUpdate(_duration);
    }
}

