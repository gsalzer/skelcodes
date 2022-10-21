// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import "./libraries/Equations.sol";
import "./libraries/FullMath.sol";
import "./libraries/TickMath.sol";
import "./libraries/UINT512.sol";

import "./interfaces/IAloePredictions.sol";

import "./AloePredictions.sol";

/// @title Aloe predictions market to run on Mainnet during the hackathon
/// @author Aloe Capital LLC
contract AloePredictionsMainnet is AloePredictions {

    constructor(IUniswapV3Pool _UNI_POOL) AloePredictions(IERC20(address(0)), _UNI_POOL) {}

    /// @dev Same as base class `advance()`, but without calling `aggregate()`. There should
    /// be no proposals on Mainnet yet.
    function advance() external override lock {
        require(uint32(block.timestamp) > epochExpectedEndTime(), "Aloe: Too early");
        epochStartTime = uint32(block.timestamp);

        if (epoch != 0) {
            (Bounds memory groundTruth, bool shouldInvertPricesNext) = fetchGroundTruth();
            emit FetchedGroundTruth(groundTruth.lower, groundTruth.upper, didInvertPrices);

            summaries[epoch - 1].groundTruth = groundTruth;
            didInvertPrices = shouldInvertPrices;
            shouldInvertPrices = shouldInvertPricesNext;
        }

        epoch++;
        emit Advanced(epoch, uint32(block.timestamp));
    }
}

