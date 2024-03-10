// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./auth/MultisigABAC.sol";
import "./wallet/TokenManager.sol";
import "./factory/BaseTemplate.sol";

contract IdentityWallet is TokenManager, MultisigABAC, BaseTemplate {
	string public constant WITHDRAW_ATTRIBUTE = "WITHDRAW";

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

	function withdrawETH(address payable to, uint256 amount) external withAttribute(WITHDRAW_ATTRIBUTE) {
		TokenManager._sendETH(to, amount);
	}

	function withdrawERC20(
		address token,
		address to,
		uint256 amount
	) external withAttribute(WITHDRAW_ATTRIBUTE) {
		TokenManager._sendERC20(token, to, amount);
	}

	function withdrawERC721(
		address token,
		address to,
		uint256 tokenId
	) external withAttribute(WITHDRAW_ATTRIBUTE) {
		TokenManager._sendERC721(token, to, tokenId);
	}

	function withdrawERC777(
		address token,
		address recipient,
		uint256 amount,
		bytes calldata data
	) external withAttribute(WITHDRAW_ATTRIBUTE) {
		TokenManager._sendERC777(token, recipient, amount, data);
	}

	function withdrawERC1155(
		address token,
		address to,
		uint256 id,
		uint256 amount,
		bytes calldata data
	) external withAttribute(WITHDRAW_ATTRIBUTE) {
		TokenManager._sendERC1155(token, to, id, amount, data);
	}
}

