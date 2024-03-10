// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IShop {
	function itemInfo(uint256 index) external view returns (uint256);

	function burn(
		address account,
		uint256 id,
		uint256 value
	) external;
}

