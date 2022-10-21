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

interface IETHtxRewardsManager {
	/* Views */

	function ethmxRewards() external view returns (address);

	function ethtx() external view returns (address);

	function ethtxAMM() external view returns (address);

	function lpRewards() external view returns (address);

	/* Mutators */

	function convertETHtx() external;

	function distributeRewards() external returns (uint256);

	function notifyRecipients() external;

	function sendRewards() external returns (uint256);

	function setEthmxRewards(address account) external;

	function setEthtx(address account) external;

	function setEthtxAMM(address account) external;

	function setLPRewards(address account) external;

	/* Events */

	event EthmxRewardsSet(address indexed author, address indexed account);
	event EthtxSet(address indexed author, address indexed account);
	event EthtxAMMSet(address indexed author, address indexed account);
	event LPRewardsSet(address indexed author, address indexed account);
	event RewardsSent(
		address indexed author,
		address indexed to,
		uint256 amount
	);
}

