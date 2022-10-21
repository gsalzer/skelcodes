pragma solidity 0.8.9;

// SPDX-License-Identifier: MIT

interface IUniswapFactory {
	function createPair(address tokenA, address tokenB) external returns (address pair);
}
