// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./auth/MultisigABAC.sol";
import "./wallet/TokenManager.sol";
import "./factory/BaseTemplate.sol";
import "./interface/IUserWallet.sol";

contract AppWallet is TokenManager, MultisigABAC, BaseTemplate {
	event CallFailed(string reason);

	// last nonce executed. Allowed to skip.
	uint256 public lastNonce;

	/// @notice Initialize the ownership policy.
	/// @dev Access control: Can only be called with a delegatecall from a contract constructor.
	/// @param owners address[] Array of owner addresses at initialization.
	/// @param admins address[] Array of admin addresses at initialization.
	/// @param ownersRequired uint256 Number of owner signatures required for valid OWNER call.
	/// @param adminsRequired uint256 Number of admin signatures required for valid ADMIN call.
	function initialize(
		address[] memory owners,
		address[] memory admins,
		uint256 ownersRequired,
		uint256 adminsRequired
	) public initializeTemplate {
		MultisigABAC._setOwnerPolicy(owners, admins, ownersRequired, adminsRequired);
	}

	/// @notice Execute transaction batch.
	/// @dev Access control: Must include valid array of ADMIN or OWNER signatures that meet admin policy.
	/// @param transactions bytes[] Array of user transaction request blobs.
	/// @param nonce uint256 Unique tx salt. Allowed to skip.
	/// @param signatures bytes[] Array of admin or owner signatures.
	/// @return success bool Boolean true if all transactions were successful, false if one or more transaction reverted.
	/// @return returnData bytes[] Array of return data from user calls.
	function executeTransactions(
		bytes[] memory transactions,
		uint256 nonce,
		bytes[] memory signatures
	)
		public
		withSignatures(keccak256(abi.encode(transactions, nonce)), signatures, ADMIN_ATTRIBUTE)
		returns (bool success, bytes[] memory returnData)
	{
		// increment nonce
		require(nonce > lastNonce, "invalid nonce");
		lastNonce = nonce;
		// execute batch atomically with external call to self in order to catch a revert
		try AppWallet(this).executeAtomicTransactions(transactions) returns (bytes[] memory _returnData) {
			return (true, _returnData);
		} catch Error(string memory reason) {
			emit CallFailed(reason);
			return (false, returnData);
		} catch {
			emit CallFailed("Transaction reverted silently");
			return (false, returnData);
		}
	}

	/// @notice Execute atomic transaction batch.
	/// @dev Access control: Can only be called by self.
	/// @param transactions bytes[] Array of user transaction request blobs.
	/// @return returnData bytes[] Array of return data from user calls.
	function executeAtomicTransactions(bytes[] memory transactions) public returns (bytes[] memory returnData) {
		// restrict to call from self
		require(msg.sender == address(this), "caller must be self");
		// Execute each transaction individually
		bytes[] memory _returnValues = new bytes[](transactions.length);
		for (uint256 i = 0; i < transactions.length; i++) {
			// Decode transaction request
			(address payable from, bytes memory transaction, bytes[] memory signatures) = abi.decode(
				transactions[i],
				(address, bytes, bytes[])
			);
			// Execute the transaction
			_returnValues[i] = IUserWallet(from).executeTransaction(transaction, signatures);
		}
		// return results
		return _returnValues;
	}
}

