// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/**
 * Babylonian square root, courtesy of dapp-bin, RJ Catalona (https://github.com/VoR0220), and Uniswap.
 * dapp-bin PR: https://github.com/ethereum/dapp-bin/pull/50/files
 * RJ Catalona's branch of dapp-bin: https://github.com/VoR0220/dapp-bin/blob/VoR0220-patch-1/library/math.sol
 * Uniswap: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/libraries/Math.sol
 */

library Sqrt {
	// babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
	function sqrt(uint256 y) internal pure returns (uint256 z) {
		if (y > 3) {
			z = y;
			uint256 x = y / 2 + 1;
			while (x < z) {
				z = x;
				x = (y / x + x) / 2;
			}
		} else if (y != 0) {
			z = 1;
		}
	}
}

