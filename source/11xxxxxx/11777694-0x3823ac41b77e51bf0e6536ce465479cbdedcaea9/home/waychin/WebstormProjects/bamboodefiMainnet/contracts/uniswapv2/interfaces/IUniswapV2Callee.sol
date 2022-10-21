// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.7.0;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

