// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

// Referencing Uniswap Example Simple Oracle
// https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/examples/ExampleOracleSimple.sol

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "./IUniswapOracle.sol";
import "../refs/CoreRef.sol";

/// @title Uniswap Oracle for ETH/USDC
/// @author Ring Protocol
/// @notice maintains the TWAP of a uniswap v3 pool contract over a specified duration
contract UsdcOracle is IUniswapOracle, CoreRef {
    using Decimal for Decimal.D256;

    /// @notice the referenced uniswap v3 pool contract
    IUniswapV3Pool public override pool;

    /// @notice the window over which the initial price will "thaw" to the true peg price
    uint32 public override duration;

    uint256 private constant USDC_DECIMALS_MULTIPLIER = 1e12; // to normalize USDC

    /// @notice UniswapOracle constructor
    /// @param _core Ring Core for reference
    /// @param _duration TWAP duration
    constructor(
        address _core,
        uint32 _duration
    ) CoreRef(_core) {
        pool = IUniswapV3Pool(address(0));

        duration = _duration;
    }

    /// @notice read the oracle price
    /// @return oracle price
    /// @return true if price is valid
    /// @dev price is to be denominated in USD per X where X can be ETH, etc.
    function read() external view override returns (Decimal.D256 memory, bool) {
        bool valid = !paused();
        return (Decimal.one().mul(USDC_DECIMALS_MULTIPLIER), valid);
    }

    /// @notice set a new duration for the TWAP window
    function setDuration(uint32 _duration) external override onlyGovernor {
        duration = _duration;
        emit DurationUpdate(_duration);
    }
}

