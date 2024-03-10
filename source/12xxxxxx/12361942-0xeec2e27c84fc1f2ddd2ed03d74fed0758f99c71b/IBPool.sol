// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IBPool {
    function getSpotPrice(
        address tokenIn,
        address tokenOut
    )
        external
        view
        returns (uint spotPrice);

    function swapExactAmountOut(
        address tokenIn,
        uint maxAmountIn,
        address tokenOut,
        uint tokenAmountOut,
        uint maxPrice
    )
        external
        returns (uint tokenAmountIn, uint spotPriceAfter);

    function swapExactAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        address tokenOut,
        uint minAmountOut,
        uint maxPrice
    )
        external
        returns (uint tokenAmountOut, uint spotPriceAfter);
}

