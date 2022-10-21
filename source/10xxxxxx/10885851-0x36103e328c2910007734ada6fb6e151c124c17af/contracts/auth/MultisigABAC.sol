// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/ECDSA.sol";
import "../wallet/MetaTxUtils.sol";

contract MultisigABAC is MetaTxUtils {
	using ECDSA for bytes32;

	// define management attributes
	string public constant OWNER_ATTRIBUTE = "OWNER";
	string public constant ADMIN_ATTRIBUTE = "ADMIN";
	uint256 public constant OWNER_ATTRIBUTE_ID = uint256(keccak256(bytes(OWNER_ATTRIBUTE)));
	uint256 public constant ADMIN_ATTRIBUTE_ID = uint256(keccak256(bytes(ADMIN_ATTRIBUTE)));

	// store issued attributes
	mapping(address => mapping(uint256 => bool)) private _issuedAttributes;
	// store attribute policies
	mapping(uint256 => uint256) private _attributePolicy;

	// define events
	event PolicySet(string attribute, uint256 attributeID, uint256 required);
	event AttributeGranted(string attribute, uint256 attributeID, address account);
	event AttributeRevoked(string attribute, uint256 attributeID, address account);

	function _setOwnerPolicy(
		address[] memory owners,
		address[] memory admins,
		uint256 ownersRequired,
		uint256 adminsRequired
	) internal {
		for (uint256 ownerIndex = 0; ownerIndex < owners.length; ownerIndex++) {
			_grantAttribute(owners[ownerIndex], OWNER_ATTRIBUTE);
		}
		for (uint256 adminIndex = 0; adminIndex < admins.length; adminIndex++) {
			_grantAttribute(admins[adminIndex], ADMIN_ATTRIBUTE);
		}
		_setPolicy(ownersRequired, OWNER_ATTRIBUTE);
		_setPolicy(adminsRequired, ADMIN_ATTRIBUTE);
	}

	// modifier with x/n policy on attribute
	modifier withAttribute(string memory attribute) {
		require(hasAttribute(msg.sender, attribute), "not authorized");
		_;
	}

	modifier withSignatures(
		bytes32 paramHash,
		bytes[] memory messageHashSignatures,
		string memory attribute
	) {
		_withSignatures(paramHash, messageHashSignatures, attribute);
		_;
	}

	// set attribute policy
	function setAttributePolicy(uint256 required, string memory attribute) public {
		_onlyOwnerOrAdmin(attribute);
		_setPolicy(required, attribute);
	}

	function setAttributePolicy(
		uint256 required,
		string memory attribute,
		bytes[] memory messageHashSignatures
	) public {
		_onlyOwnerOrAdmin(keccak256(abi.encode(attribute, required)), attribute, messageHashSignatures);
		_setPolicy(required, attribute);
	}

	// grant attribute
	function grantAttribute(address account, string memory attribute) public {
		_onlyOwnerOrAdmin(attribute);
		_grantAttribute(account, attribute);
	}

	function grantAttribute(
		address account,
		string memory attribute,
		bytes[] memory messageHashSignatures
	) public {
		_onlyOwnerOrAdmin(keccak256(abi.encode(account, attribute)), attribute, messageHashSignatures);
		_grantAttribute(account, attribute);
	}

	// revoke attribute
	function revokeAttribute(address account, string memory attribute) public {
		_onlyOwnerOrAdmin(attribute);
		_revokeAttribute(account, attribute);
	}

	function revokeAttribute(
		address account,
		string memory attribute,
		bytes[] memory messageHashSignatures
	) public {
		_onlyOwnerOrAdmin(keccak256(abi.encode(account)), attribute, messageHashSignatures);
		_revokeAttribute(account, attribute);
	}

	// transfer attribute
	function transferAttribute(
		address oldAccount,
		address newAccount,
		string memory attribute
	) public {
		_onlyOwnerOrAdmin(attribute);
		_transferAttribute(oldAccount, newAccount, attribute);
	}

	function transferAttribute(
		address oldAccount,
		address newAccount,
		string memory attribute,
		bytes[] memory messageHashSignatures
	) public {
		_onlyOwnerOrAdmin(keccak256(abi.encode(oldAccount, newAccount, attribute)), attribute, messageHashSignatures);
		_transferAttribute(oldAccount, newAccount, attribute);
	}

	// internal
	function _setPolicy(uint256 required, string memory attribute) internal {
		uint256 attributeID = stringToUint(attribute);
		_attributePolicy[attributeID] = required;
		emit PolicySet(attribute, attributeID, required);
	}

	function _grantAttribute(address account, string memory attribute) internal {
		uint256 attributeID = stringToUint(attribute);
		require(!_issuedAttributes[account][attributeID], "attribute already held");
		_issuedAttributes[account][attributeID] = true;
		emit AttributeGranted(attribute, attributeID, account);
	}

	function _revokeAttribute(address account, string memory attribute) internal {
		uint256 attributeID = stringToUint(attribute);
		require(_issuedAttributes[account][attributeID], "attribute not held");
		delete _issuedAttributes[account][attributeID];
		emit AttributeRevoked(attribute, attributeID, account);
	}

	function _transferAttribute(
		address oldAccount,
		address newAccount,
		string memory attribute
	) internal {
		_revokeAttribute(oldAccount, attribute);
		_grantAttribute(newAccount, attribute);
	}

	// getters
	function getPolicy(string memory attribute) public view returns (uint256 required) {
		return _attributePolicy[stringToUint(attribute)];
	}

	function hasAttribute(address account, string memory attribute) public view returns (bool valid) {
		return _issuedAttributes[account][stringToUint(attribute)] || _issuedAttributes[account][OWNER_ATTRIBUTE_ID];
	}

	function hasAttribute(
		bytes32 messageHash,
		bytes memory messageHashSignature,
		string memory attribute
	) public view returns (bool valid) {
		return hasAttribute(messageHash.recover(messageHashSignature), attribute);
	}

	function haveAttribute(
		bytes32 messageHash,
		bytes[] memory messageHashSignatures,
		string memory attribute
	) public view returns (bool valid) {
		for (uint256 index = 0; index < messageHashSignatures.length; index++) {
			valid = hasAttribute(messageHash, messageHashSignatures[index], attribute);
			if (!valid) {
				return valid;
			}
		}
		return valid;
	}

	function stringToUint(string memory attribute) public pure returns (uint256 attributeID) {
		return uint256(keccak256(bytes(attribute)));
	}

	function _withSignatures(
		bytes32 paramHash,
		bytes[] memory messageHashSignatures,
		string memory attribute
	) internal view {
		bytes32 messageHash = keccak256(abi.encode(address(this), msg.sig, MetaTxUtils.getChainId(), paramHash))
			.toEthSignedMessageHash();
		require(messageHashSignatures.length >= getPolicy(attribute), "insuficient signatures");
		require(haveAttribute(messageHash, messageHashSignatures, attribute), "signatures not authorized");
	}

	// private

	function _onlyOwnerOrAdmin(
		bytes32 paramsHash,
		string memory attribute,
		bytes[] memory messageHashSignatures
	) private view {
		uint256 attributeID = stringToUint(attribute);
		if (attributeID == OWNER_ATTRIBUTE_ID || attributeID == ADMIN_ATTRIBUTE_ID) {
			_withSignatures(paramsHash, messageHashSignatures, OWNER_ATTRIBUTE);
		} else {
			_withSignatures(paramsHash, messageHashSignatures, ADMIN_ATTRIBUTE);
		}
	}

	function _onlyOwnerOrAdmin(string memory attribute) private view {
		uint256 attributeID = stringToUint(attribute);
		if (attributeID == OWNER_ATTRIBUTE_ID || attributeID == ADMIN_ATTRIBUTE_ID) {
			require(hasAttribute(msg.sender, OWNER_ATTRIBUTE), "not authorized");
		} else {
			require(hasAttribute(msg.sender, ADMIN_ATTRIBUTE), "not authorized");
		}
	}
}

