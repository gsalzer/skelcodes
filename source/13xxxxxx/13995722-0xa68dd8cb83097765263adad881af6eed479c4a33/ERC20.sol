// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ERC20 {
	function allowance(address, address) external view returns (uint256);
	function balanceOf(address) external view returns (uint256);
	function transfer(address, uint256) external returns (bool);
	function transferFrom(address, address, uint256) external returns (bool);
}
