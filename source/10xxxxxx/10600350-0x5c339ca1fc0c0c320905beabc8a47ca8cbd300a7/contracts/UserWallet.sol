// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./auth/MultisigABAC.sol";
import "./wallet/MetaTxUtils.sol";
import "./wallet/TokenManager.sol";
import "./factory/BaseTemplate.sol";
import "@nomiclabs/buidler/console.sol";

contract UserWallet is TokenManager, MetaTxUtils, MultisigABAC, BaseTemplate {
	// last nonce executed. Allowed to skip.
	uint256 public previousNonce;

	event CallFailed(string reason);

	struct Result {
		bool success;
		bytes result;
		uint256 gasUsed;
	}

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

	/// @notice Execute transaction.
	/// @dev Access control: Must include valid array of ADMIN or OWNER signatures that meet admin policy.
	/// @param transaction bytes Encoded transaction blob: (address to, uint256 value, uint256 gasLimit, uint256 nonce, bytes memory data)
	/// @param signatures bytes[] Array of admin or owner signatures: ethSign(keccak256(transaction))
	/// @return result bytes Encoded return data from user call.
	function executeSingle(bytes memory transaction, bytes[] memory signatures)
		public
		withSignatures(keccak256(transaction), signatures, ADMIN_ATTRIBUTE)
		returns (bytes memory result)
	{
		return _executeTransaction(transaction);
	}

	/// @notice Execute transactions.
	/// @dev Access control: Must include valid array of ADMIN or OWNER signatures that meet admin policy.
	/// @param transactions bytes[] Array of encoded transaction blobs: (address to, uint256 value, uint256 gasLimit, uint256 nonce, bytes memory data)
	/// @param signatures bytes[] Array of admin or owner signatures: ethSign(keccak256(abi.encode(transactions)))
	/// @return success bool Boolean true if all transactions were successful, false if one or more transaction reverted.
	/// @return result bytes[] Array of return data from user calls.
	function executeMulti(bytes[] memory transactions, bytes[] memory signatures)
		public
		withSignatures(keccak256(abi.encode(transactions)), signatures, ADMIN_ATTRIBUTE)
		returns (bool success, bytes[] memory result)
	{
		// execute batch atomically with external call to self in order to catch a revert
		try this._executeAtomic(transactions) returns (bytes[] memory _result) {
			return (true, _result);
		} catch Error(string memory reason) {
			emit CallFailed(reason);
			return (false, result);
		}
	}

	/// @notice Execute atomic transaction batch.
	/// @dev Access control: Can only be called by self.
	/// @param transactions bytes[] Array of user transaction request blobs: (address to, uint256 value, uint256 gasLimit, uint256 nonce, bytes memory data)
	/// @return result bytes[] Array of return data from user calls.
	function _executeAtomic(bytes[] memory transactions) public returns (bytes[] memory result) {
		// restrict to call from self
		require(msg.sender == address(this), "caller must be self");
		// Execute each transaction individually
		bytes[] memory _result = new bytes[](transactions.length);
		for (uint256 i = 0; i < transactions.length; i++) {
			// Execute the transaction
			_result[i] = _executeTransaction(transactions[i]);
		}
		// return results
		return _result;
	}

	/// @notice Execute transaction helper.
	/// @param transaction bytes Encoded transaction blob: (address to, uint256 value, uint256 gasLimit, uint256 nonce, bytes memory data)
	/// @return result bytes Encoded return data from user call.
	function _executeTransaction(bytes memory transaction) private returns (bytes memory result) {
		// decode transaction
		(address to, uint256 value, uint256 gasLimit, uint256 nonce, bytes memory data) = abi.decode(
			transaction,
			(address, uint256, uint256, uint256, bytes)
		);
		// increment nonce
		require(nonce > previousNonce, "invalid nonce");
		previousNonce = nonce;
		// perform external call
		(bool success, bytes memory res) = to.call{gas: gasLimit, value: value}(data);
		// get the revert message of the call and revert with it if the call failed
		if (!success) {
			string memory revertMsg = MetaTxUtils._getRevertMsg(res);
			revert(revertMsg);
		}
		// return results
		return res;
	}
}

