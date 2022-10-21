// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

interface IUserWallet {
	function executeTransaction(bytes calldata transaction, bytes[] calldata signatures)
		external
		returns (bytes memory returnData);
}

