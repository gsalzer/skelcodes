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

interface IETHmxRewards {
	/* Views */

	function accrualUpdateInterval() external view returns (uint256);

	function accruedRewardsPerToken() external view returns (uint256);

	function accruedRewardsPerTokenLast(address account)
		external
		view
		returns (uint256);

	function ethmx() external view returns (address);

	function lastAccrualUpdate() external view returns (uint256);

	function lastRewardsBalanceOf(address account)
		external
		view
		returns (uint256);

	function lastStakedBalanceOf(address account)
		external
		view
		returns (uint256);

	function lastTotalRewardsAccrued() external view returns (uint256);

	function readyForUpdate() external view returns (bool);

	function rewardsBalanceOf(address account) external view returns (uint256);

	function stakedBalanceOf(address account) external view returns (uint256);

	function totalRewardsAccrued() external view returns (uint256);

	function totalRewardsRedeemed() external view returns (uint256);

	function totalStaked() external view returns (uint256);

	function unredeemableRewards() external view returns (uint256);

	function weth() external view returns (address);

	/* Mutators */

	function exit(bool asWETH) external;

	function pause() external;

	function recoverUnredeemableRewards(address to, uint256 amount) external;

	function recoverUnstaked(address to, uint256 amount) external;

	function recoverUnsupportedERC20(
		address token,
		address to,
		uint256 amount
	) external;

	function redeemAllRewards(bool asWETH) external;

	function redeemReward(uint256 amount, bool asWETH) external;

	function setAccrualUpdateInterval(uint256 interval) external;

	function setEthmx(address account) external;

	function setWeth(address account) external;

	function stake(uint256 amount) external;

	function unpause() external;

	function unstake(uint256 amount) external;

	function unstakeAll() external;

	function updateAccrual() external;

	function updateReward() external;

	/* Events */

	event AccrualUpdated(address indexed author, uint256 accruedRewards);
	event AccrualUpdateIntervalSet(address indexed author, uint256 interval);
	event ETHmxSet(address indexed author, address indexed account);
	event RecoveredUnredeemableRewards(
		address indexed author,
		address indexed to,
		uint256 amount
	);
	event RecoveredUnstaked(
		address indexed author,
		address indexed to,
		uint256 amount
	);
	event RecoveredUnsupported(
		address indexed author,
		address indexed token,
		address indexed to,
		uint256 amount
	);
	event RewardPaid(address indexed to, uint256 amount);
	event Staked(address indexed account, uint256 amount);
	event Unstaked(address indexed account, uint256 amount);
	event WETHSet(address indexed author, address indexed account);
}

