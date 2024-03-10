// SPDX-License-Identifier: Apache-2.0

/**
 * Copyright 2021 weiWard LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.7.6;

interface IAccessControl {
	/* Views */

	function getRoleAdmin(bytes32 role) external view returns (bytes32);

	function hasRole(bytes32 role, address account) external view returns (bool);

	/* Mutators */

	function grantRole(bytes32 role, address account) external;

	function revokeRole(bytes32 role, address account) external;

	function renounceRole(bytes32 role, address account) external;

	/* Events */
	event RoleAdminChanged(
		bytes32 indexed role,
		bytes32 indexed previousAdminRole,
		bytes32 indexed newAdminRole
	);
	event RoleGranted(
		bytes32 indexed role,
		address indexed account,
		address indexed sender
	);
	event RoleRevoked(
		bytes32 indexed role,
		address indexed account,
		address indexed sender
	);
}

