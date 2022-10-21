// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface Uniswap {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

