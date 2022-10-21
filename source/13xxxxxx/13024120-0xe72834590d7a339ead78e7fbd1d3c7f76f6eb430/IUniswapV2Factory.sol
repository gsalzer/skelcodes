// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
