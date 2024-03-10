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

import "../access/AccessControl/AccessControl.sol";

interface IGasPrice {
	function setGasPrice(uint256) external;
}

interface IETHtx {
	function rebase() external;
}

contract Policy is AccessControl {
	bytes32 public constant POLICY_ROLE = keccak256("POLICY_ROLE");

	address public immutable ethtx;
	address public immutable gasOracle;

	constructor(
		address admin,
		address policyMaker,
		address gasOracle_,
		address ethtx_
	) {
		_setupRole(DEFAULT_ADMIN_ROLE, admin);
		_setupRole(POLICY_ROLE, policyMaker);
		ethtx = ethtx_;
		gasOracle = gasOracle_;
	}

	function update(uint256 gasPrice) external onlyRole(POLICY_ROLE) {
		IGasPrice(gasOracle).setGasPrice(gasPrice);
		IETHtx(ethtx).rebase();
	}
}

