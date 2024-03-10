// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface INFTSale {
	function stake(uint256 nftID, address payable artist, uint32 amount, uint256 price, uint256 startTime, bytes calldata data) external;
}
