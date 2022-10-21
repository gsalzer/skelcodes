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

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./IMultiSend.sol";

contract MultiSend is IMultiSend {
	using Address for address payable;
	using SafeERC20 for IERC20;

	// WARN: Potential reentrancy vulnerability
	function multiSendETH(Recipient[] memory recipients)
		external
		payable
		override
	{
		address sender = msg.sender;
		uint256 total = msg.value;
		uint256 sent = 0;

		for (uint256 i = 0; i < recipients.length; i++) {
			payable(recipients[i].to).sendValue(recipients[i].amount);
			sent += recipients[i].amount;
		}

		if (sent != total) {
			payable(sender).sendValue(total - sent);
		}

		emit ETHSent(sender, recipients);
	}

	function multiSendERC20(address token, Recipient[] memory recipients)
		external
		override
	{
		address sender = msg.sender;
		IERC20 tokenHandle = IERC20(token);

		for (uint256 i = 0; i < recipients.length; i++) {
			tokenHandle.safeTransferFrom(
				sender,
				recipients[i].to,
				recipients[i].amount
			);
		}

		emit ERC20Sent(sender, token, recipients);
	}

	// Recover ERC20 tokens accidentally sent to the contract
	function recoverERC20(
		address token,
		address to,
		uint256 amount
	) external override {
		IERC20(token).safeTransfer(to, amount);
		emit RecoveredERC20(msg.sender, token, to, amount);
	}
}

