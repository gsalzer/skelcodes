// SPDX-License-Identifier: Apache-2.0

/**
 * Copyright 2021 weiWard LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/IValuePerToken.sol";
import "../libraries/Sqrt.sol";

interface IUniswapV2Factory {
	function feeTo() external view returns (address);
}

interface IUniswapV2Pair {
	function factory() external view returns (address);

	function getReserves()
		external
		view
		returns (
			uint112 reserve0,
			uint112 reserve1,
			uint32 blockTimestampLast
		);

	function kLast() external view returns (uint256);

	function token0() external view returns (address);

	function token1() external view returns (address);

	function totalSupply() external view returns (uint256);
}

contract ValuePerUNIV2 is IValuePerToken {
	using SafeMath for uint256;

	/* Immutable Public State */

	address public immutable override token;
	address public immutable valueToken;

	/* Constructor */

	constructor(address _token, address _valueToken) {
		IUniswapV2Pair tokenHandle = IUniswapV2Pair(_token);
		address token0 = tokenHandle.token0();
		address token1 = tokenHandle.token1();

		require(
			_valueToken == token0 || _valueToken == token1,
			"ValuePerUNIV2: pool lacks token"
		);

		token = _token;
		valueToken = _valueToken;
	}

	/* External Views */

	function valuePerToken()
		external
		view
		override
		returns (uint256 numerator, uint256 denominator)
	{
		IUniswapV2Pair tokenHandle = IUniswapV2Pair(token);
		uint256 totalSupply = tokenHandle.totalSupply();
		(uint112 reserve0, uint112 reserve1, ) = tokenHandle.getReserves();

		// Adjust totalSupply when feeOn
		// Minted fee liquidity is equivalent to 1/6th of the growth in sqrt(k)
		if (feeOn()) {
			uint256 kLast = tokenHandle.kLast();
			if (kLast > 0) {
				uint256 rootK = Sqrt.sqrt(uint256(reserve0).mul(reserve1));
				uint256 rootKLast = Sqrt.sqrt(kLast);
				if (rootK > rootKLast) {
					uint256 n = totalSupply.mul(rootK - rootKLast);
					uint256 d = rootK.mul(5).add(rootKLast);
					uint256 feeLiquidity = n / d;
					totalSupply = totalSupply.add(feeLiquidity);
				}
			}
		}

		address token0 = tokenHandle.token0();

		// Use correct reserve
		numerator = valueToken == token0 ? reserve0 : reserve1;
		denominator = totalSupply;
	}

	/* Public Views */

	function feeOn() public view returns (bool) {
		address factory = IUniswapV2Pair(token).factory();
		address feeTo = IUniswapV2Factory(factory).feeTo();
		return feeTo != address(0);
	}
}

