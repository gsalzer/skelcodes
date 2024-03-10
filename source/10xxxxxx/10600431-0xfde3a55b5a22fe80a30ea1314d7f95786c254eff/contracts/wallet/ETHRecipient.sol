// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

contract ETHRecipient {
	event ReceivedETH();

	receive() external payable {
		emit ReceivedETH();
	}
}

