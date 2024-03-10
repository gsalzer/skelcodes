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

pragma solidity 0.8.6;

interface IMultiSend {
	/* Types */

	struct Recipient {
		address to;
		uint256 amount;
	}

	/* Mutators */

	function multiSendETH(Recipient[] memory recipients) external payable;

	function multiSendERC20(address token, Recipient[] memory recipients)
		external;

	function recoverERC20(
		address token,
		address to,
		uint256 amount
	) external;

	/* Events */

	event ETHSent(address indexed from, Recipient[] recipients);
	event ERC20Sent(
		address indexed from,
		address indexed token,
		Recipient[] recipients
	);
	event RecoveredERC20(
		address indexed author,
		address indexed token,
		address indexed to,
		uint256 amount
	);
}

