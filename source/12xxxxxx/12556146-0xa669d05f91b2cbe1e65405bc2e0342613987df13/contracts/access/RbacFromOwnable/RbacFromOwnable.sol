// SPDX-License-Identifier: MIT

/**
 * From https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/aeb86bf4f438e0fedb5eecc3dd334fd6544ab1f6/contracts/access/AccessControlUpgradeable.sol
 *
 * Changes:
 * - Compiled for 0.7.6
 * - Removed ERC165 Introspection
 * - Moved state to RbacFromOwnableData
 * - Added _ownerDeprecated for upgrading from OwnableUpgradeable
 * - Removed _checkRole
 * - Reformatted styling in line with this repository.
 */

/*
The MIT License (MIT)

Copyright (c) 2016-2020 zOS Global Limited

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import "./RbacFromOwnableData.sol";
import "../interfaces/IAccessControl.sol";

/* solhint-disable func-name-mixedcase */

abstract contract RbacFromOwnable is
	Initializable,
	ContextUpgradeable,
	RbacFromOwnableData,
	IAccessControl
{
	bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

	/* Initializer */

	function __RbacFromOwnable_init() internal initializer {
		__Context_init_unchained();
	}

	function __RbacFromOwnable_init_unchained() internal initializer {
		return;
	}

	/* Modifiers */

	modifier onlyRole(bytes32 role) {
		require(hasRole(role, _msgSender()), "AccessControl: access denied");
		_;
	}

	/* External Views */

	function hasRole(bytes32 role, address account)
		public
		view
		override
		returns (bool)
	{
		return _roles[role].members[account];
	}

	function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
		return _roles[role].adminRole;
	}

	/* External Mutators */

	function grantRole(bytes32 role, address account)
		public
		virtual
		override
		onlyRole(getRoleAdmin(role))
	{
		_grantRole(role, account);
	}

	function revokeRole(bytes32 role, address account)
		public
		virtual
		override
		onlyRole(getRoleAdmin(role))
	{
		_revokeRole(role, account);
	}

	function renounceRole(bytes32 role, address account)
		public
		virtual
		override
	{
		require(
			account == _msgSender(),
			"AccessControl: can only renounce roles for self"
		);

		_revokeRole(role, account);
	}

	/* Internal Mutators */

	function _setupRole(bytes32 role, address account) internal virtual {
		_grantRole(role, account);
	}

	function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
		emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
		_roles[role].adminRole = adminRole;
	}

	function _grantRole(bytes32 role, address account) private {
		if (!hasRole(role, account)) {
			_roles[role].members[account] = true;
			emit RoleGranted(role, account, _msgSender());
		}
	}

	function _revokeRole(bytes32 role, address account) private {
		if (hasRole(role, account)) {
			_roles[role].members[account] = false;
			emit RoleRevoked(role, account, _msgSender());
		}
	}
}

