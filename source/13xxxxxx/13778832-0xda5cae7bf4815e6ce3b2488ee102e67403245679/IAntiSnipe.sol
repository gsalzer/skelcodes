pragma solidity 0.8.10;

// SPDX-License-Identifier: MIT

interface IAntiSnipe {
	function process(address from, address to) external;

	function launch(address pairAddress) external;
}
