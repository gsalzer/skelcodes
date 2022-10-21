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

library UintLog {
	uint256 internal constant _LOG2_E = 1442695040888963407;

	function ln(uint256 x) internal pure returns (uint256) {
		return (blog2(x) * 1e18) / _LOG2_E;
	}

	// Most significant bit
	// prettier-ignore
	function msb(uint256 x) internal pure returns (uint256 n) {
		if (x >= 0x100000000000000000000000000000000) { x >>= 128; n += 128; }
		if (x >= 0x10000000000000000) { x >>= 64; n += 64; }
		if (x >= 0x100000000) { x >>= 32; n += 32; }
		if (x >= 0x10000) { x >>= 16; n += 16; }
		if (x >= 0x100) { x >>= 8; n += 8; }
		if (x >= 0x10) { x >>= 4; n += 4; }
		if (x >= 0x4) { x >>= 2; n += 2; }
		if (x >= 0x2) { /* x >>= 1; */ n += 1; }
	}

	// Approximate binary log of uint
	// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
	// https://github.com/hifi-finance/prb-math/blob/5c6817860496ec40fd269934f3c531822402f1ce/contracts/PRBMathUD60x18.sol#L334-L380
	function blog2(uint256 x) internal pure returns (uint256 result) {
		require(x >= 1e18, "blog2 too small");
		uint256 n = msb(x / 1e18);

		result = n * 1e18;
		uint256 y = x >> n;

		if (y == 1e18) {
			return result;
		}

		for (uint256 delta = 5e17; delta > 0; delta >>= 1) {
			y = (y * y) / 1e18;
			if (y >= 2e18) {
				result += delta;
				y >>= 1;
			}
		}
	}
}

