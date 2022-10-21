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

interface IFeeLogic {
	/* Types */

	struct ExemptData {
		address account;
		bool isExempt;
	}

	/* Views */

	function exemptsAt(uint256 index) external view returns (address);

	function exemptsLength() external view returns (uint256);

	function feeRate()
		external
		view
		returns (uint128 numerator, uint128 denominator);

	function getFee(
		address sender,
		address recipient_,
		uint256 amount
	) external view returns (uint256);

	function isExempt(address account) external view returns (bool);

	function recipient() external view returns (address);

	function undoFee(
		address sender,
		address recipient_,
		uint256 amount
	) external view returns (uint256);

	/* Mutators */

	function notify(uint256 amount) external;

	function setExempt(address account, bool isExempt_) external;

	function setExemptBatch(ExemptData[] memory batch) external;

	function setFeeRate(uint128 numerator, uint128 denominator) external;

	function setRecipient(address account) external;

	/* Events */

	event ExemptAdded(address indexed author, address indexed account);
	event ExemptRemoved(address indexed author, address indexed account);
	event FeeRateSet(
		address indexed author,
		uint128 numerator,
		uint128 denominator
	);
	event RecipientSet(address indexed author, address indexed account);
}

