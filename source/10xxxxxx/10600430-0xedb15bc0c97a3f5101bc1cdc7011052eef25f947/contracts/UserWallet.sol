// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./auth/MultisigABAC.sol";
import "./wallet/MetaTxUtils.sol";
import "./wallet/TokenManager.sol";
import "./factory/BaseTemplate.sol";

contract UserWallet is TokenManager, MetaTxUtils, MultisigABAC, BaseTemplate {
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

	/// @notice Execute transaction.
	/// @dev Access control: Must include valid array of ADMIN or OWNER signatures that meet admin policy.
	/// @param transaction bytes Encoded transaction blob.
	/// @param signatures bytes[] Array of admin or owner signatures.
	/// @return returnData bytes Encoded return data from user call.
	function executeTransaction(bytes memory transaction, bytes[] memory signatures)
		public
		withSignatures(keccak256(transaction), signatures, ADMIN_ATTRIBUTE)
		returns (bytes memory returnData)
	{
		(address to, uint256 value, uint256 gasLimit, uint256 nonce, bytes memory data) = MetaTxUtils
			._decodeTransaction(transaction);
		// increment nonce
		require(nonce > lastNonce, "invalid nonce");
		lastNonce = nonce;
		// execute tx
		return MetaTxUtils._executeTransaction(to, value, gasLimit, data);
	}
}

