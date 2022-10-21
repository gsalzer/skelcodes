// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface UniswapV2Helper {
    function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1);

    function pairFor(address tokenA, address tokenB) external view returns (address pair);

    function getFactoryAddress() external view returns (address factory);

    function getRouterAddress() external view returns (address router);

    function getUniswapV2OracleAddress() external view returns (address oracle);
}
