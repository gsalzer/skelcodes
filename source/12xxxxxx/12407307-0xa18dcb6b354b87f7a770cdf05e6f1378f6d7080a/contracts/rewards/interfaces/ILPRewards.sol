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

interface ILPRewards {
	/* Views */

	function accruedRewardsPerTokenFor(address token)
		external
		view
		returns (uint256);

	function accruedRewardsPerTokenLastFor(address account, address token)
		external
		view
		returns (uint256);

	function lastRewardsBalanceOf(address account)
		external
		view
		returns (uint256);

	function lastRewardsBalanceOfFor(address account, address token)
		external
		view
		returns (uint256);

	function lastTotalRewardsAccrued() external view returns (uint256);

	function lastTotalRewardsAccruedFor(address token)
		external
		view
		returns (uint256);

	function numStakingTokens() external view returns (uint256);

	function rewardsBalanceOf(address account) external view returns (uint256);

	function rewardsBalanceOfFor(address account, address token)
		external
		view
		returns (uint256);

	function rewardsForToken(address token) external view returns (uint256);

	function rewardsToken() external view returns (address);

	function sharesFor(address account, address token)
		external
		view
		returns (uint256);

	function sharesPerToken(address token) external view returns (uint256);

	function stakedBalanceOf(address account, address token)
		external
		view
		returns (uint256);

	function stakingTokenAt(uint256 index) external view returns (address);

	function supportsStakingToken(address token) external view returns (bool);

	function totalRewardsAccrued() external view returns (uint256);

	function totalRewardsAccruedFor(address token)
		external
		view
		returns (uint256);

	function totalRewardsRedeemed() external view returns (uint256);

	function totalRewardsRedeemedFor(address token)
		external
		view
		returns (uint256);

	function totalShares() external view returns (uint256);

	function totalSharesFor(address account) external view returns (uint256);

	function totalSharesForToken(address token) external view returns (uint256);

	function totalStaked(address token) external view returns (uint256);

	function unredeemableRewards() external view returns (uint256);

	function valuePerTokenImpl(address token) external view returns (address);

	/* Mutators */

	function addToken(address token, address tokenValueImpl) external;

	function changeTokenValueImpl(address token, address tokenValueImpl)
		external;

	function exit(bool asWETH) external;

	function exitFrom(address token, bool asWETH) external;

	function pause() external;

	function recoverUnredeemableRewards(address to, uint256 amount) external;

	function recoverUnstaked(
		address token,
		address to,
		uint256 amount
	) external;

	function redeemAllRewards(bool asWETH) external;

	function redeemAllRewardsFrom(address token, bool asWETH) external;

	function redeemReward(uint256 amount, bool asWETH) external;

	function redeemRewardFrom(
		address token,
		uint256 amount,
		bool asWETH
	) external;

	function removeToken(address token) external;

	function setRewardsToken(address token) external;

	function stake(address token, uint256 amount) external;

	function unpause() external;

	function unstake(address token, uint256 amount) external;

	function unstakeAll() external;

	function unstakeAllFrom(address token) external;

	function updateAccrual() external;

	function updateReward() external;

	function updateRewardFor(address token) external;

	/* Events */

	event AccrualUpdated(address indexed author, uint256 accruedRewards);
	event RecoveredUnredeemableRewards(
		address indexed author,
		address indexed to,
		uint256 amount
	);
	event RecoveredUnstaked(
		address indexed author,
		address indexed token,
		address indexed to,
		uint256 amount
	);
	event RewardPaid(
		address indexed account,
		address indexed token,
		uint256 amount
	);
	event RewardsTokenSet(address indexed author, address indexed token);
	event Staked(address indexed account, address indexed token, uint256 amount);
	event TokenAdded(
		address indexed author,
		address indexed token,
		address indexed tokenValueImpl
	);
	event TokenRemoved(address indexed author, address indexed token);
	event TokenValueImplChanged(
		address indexed author,
		address indexed token,
		address indexed tokenValueImpl
	);
	event Unstaked(
		address indexed account,
		address indexed token,
		uint256 amount
	);
}

