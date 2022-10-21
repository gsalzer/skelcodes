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
pragma abicoder v2;

interface IRewardsManager {
	/* Types */

	struct ShareData {
		address account;
		uint128 value;
		bool isActive;
	}

	/* Views */

	function defaultRecipient() external view returns (address);

	function rewardsToken() external view returns (address);

	function sharesFor(address account)
		external
		view
		returns (uint128 active, uint128 total);

	function totalRewardsAccrued() external view returns (uint256);

	function totalRewardsRedeemed() external view returns (uint256);

	function totalShares() external view returns (uint256);

	/* Mutators */

	function activateShares() external;

	function activateSharesFor(address account) external;

	function addShares(address account, uint128 amount) external;

	function deactivateShares() external;

	function deactivateSharesFor(address account) external;

	function recoverUnsupportedERC20(
		address token,
		address to,
		uint256 amount
	) external;

	function removeShares(address account, uint128 amount) external;

	function setDefaultRecipient(address account) external;

	function setRewardsToken(address token) external;

	function setShares(
		address account,
		uint128 value,
		bool isActive
	) external;

	function setSharesBatch(ShareData[] memory batch) external;

	/* Events */

	event DefaultRecipientSet(address indexed author, address indexed account);
	event RecoveredUnsupported(
		address indexed author,
		address indexed token,
		address indexed to,
		uint256 amount
	);
	event RewardsTokenSet(address indexed author, address indexed token);
	event SharesActivated(address indexed author, address indexed account);
	event SharesAdded(
		address indexed author,
		address indexed account,
		uint128 amount
	);
	event SharesDeactivated(address indexed author, address indexed account);
	event SharesRemoved(
		address indexed author,
		address indexed account,
		uint128 amount
	);
	event SharesSet(
		address indexed author,
		address indexed account,
		uint128 value,
		bool isActive
	);
}

