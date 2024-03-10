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

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./LPRewardsData.sol";
import "../../libraries/EnumerableMap.sol";
import "../interfaces/ILPRewards.sol";
import "../interfaces/IValuePerToken.sol";
import "../../tokens/interfaces/IWETH.sol";
import "../../access/OwnableUpgradeable.sol";

contract LPRewards is
	Initializable,
	ContextUpgradeable,
	OwnableUpgradeable,
	PausableUpgradeable,
	LPRewardsData,
	ILPRewards
{
	using Address for address payable;
	using EnumerableMap for EnumerableMap.AddressToUintMap;
	using EnumerableSet for EnumerableSet.AddressSet;
	using SafeERC20 for IERC20;
	using SafeMath for uint256;

	/* Immutable Internal State */

	uint256 internal constant _MULTIPLIER = 1e36;

	/* Constructor */

	constructor(address owner_) {
		init(owner_);
	}

	/* Initializers */

	function init(address owner_) public virtual initializer {
		__Context_init_unchained();
		__Ownable_init_unchained(owner_);
		__Pausable_init_unchained();
	}

	/* Fallbacks */

	receive() external payable {
		// Only accept ETH via fallback from the WETH contract
		require(msg.sender == _rewardsToken);
	}

	/* Modifiers */

	modifier supportsToken(address token) {
		require(supportsStakingToken(token), "LPRewards: unsupported token");
		_;
	}

	/* Public Views */

	function accruedRewardsPerTokenFor(address token)
		public
		view
		virtual
		override
		returns (uint256)
	{
		return _tokenData[token].arpt;
	}

	function accruedRewardsPerTokenLastFor(address account, address token)
		public
		view
		virtual
		override
		returns (uint256)
	{
		return _users[account].rewardsFor[token].arptLast;
	}

	function lastRewardsBalanceOf(address account)
		public
		view
		virtual
		override
		returns (uint256 total)
	{
		UserData storage user = _users[account];
		EnumerableSet.AddressSet storage tokens = user.tokensWithRewards;
		for (uint256 i = 0; i < tokens.length(); i++) {
			total += user.rewardsFor[tokens.at(i)].pending;
		}
	}

	function lastRewardsBalanceOfFor(address account, address token)
		public
		view
		virtual
		override
		returns (uint256)
	{
		return _users[account].rewardsFor[token].pending;
	}

	function lastTotalRewardsAccrued()
		external
		view
		virtual
		override
		returns (uint256)
	{
		return _lastTotalRewardsAccrued;
	}

	function lastTotalRewardsAccruedFor(address token)
		external
		view
		virtual
		override
		returns (uint256)
	{
		return _tokenData[token].lastRewardsAccrued;
	}

	function numStakingTokens()
		external
		view
		virtual
		override
		returns (uint256)
	{
		return _tokens.length();
	}

	function rewardsBalanceOf(address account)
		external
		view
		virtual
		override
		returns (uint256)
	{
		return lastRewardsBalanceOf(account) + _allPendingRewardsFor(account);
	}

	function rewardsBalanceOfFor(address account, address token)
		external
		view
		virtual
		override
		returns (uint256)
	{
		uint256 rewards = lastRewardsBalanceOfFor(account, token);
		uint256 amountStaked = stakedBalanceOf(account, token);
		if (amountStaked != 0) {
			rewards += _pendingRewardsFor(account, token, amountStaked);
		}
		return rewards;
	}

	function rewardsForToken(address token)
		external
		view
		virtual
		override
		returns (uint256)
	{
		return _tokenData[token].rewards;
	}

	function rewardsToken() public view virtual override returns (address) {
		return _rewardsToken;
	}

	function sharesFor(address account, address token)
		external
		view
		virtual
		override
		returns (uint256)
	{
		return _shares(token, stakedBalanceOf(account, token));
	}

	function sharesPerToken(address token)
		external
		view
		virtual
		override
		returns (uint256)
	{
		return _shares(token, 1e18);
	}

	function stakedBalanceOf(address account, address token)
		public
		view
		virtual
		override
		returns (uint256)
	{
		EnumerableMap.AddressToUintMap storage staked = _users[account].staked;
		if (staked.contains(token)) {
			return staked.get(token);
		}
		return 0;
	}

	function stakingTokenAt(uint256 index)
		external
		view
		virtual
		override
		returns (address)
	{
		return _tokens.at(index);
	}

	function supportsStakingToken(address token)
		public
		view
		virtual
		override
		returns (bool)
	{
		return _tokens.contains(token);
	}

	function totalRewardsAccrued()
		public
		view
		virtual
		override
		returns (uint256)
	{
		// Overflow is OK
		return _currentRewardsBalance() + _totalRewardsRedeemed;
	}

	function totalRewardsAccruedFor(address token)
		public
		view
		virtual
		override
		returns (uint256)
	{
		TokenData storage td = _tokenData[token];
		// Overflow is OK
		return td.rewards + td.rewardsRedeemed;
	}

	function totalRewardsRedeemed()
		external
		view
		virtual
		override
		returns (uint256)
	{
		return _totalRewardsRedeemed;
	}

	function totalRewardsRedeemedFor(address token)
		external
		view
		virtual
		override
		returns (uint256)
	{
		return _tokenData[token].rewardsRedeemed;
	}

	function totalShares()
		external
		view
		virtual
		override
		returns (uint256 total)
	{
		for (uint256 i = 0; i < _tokens.length(); i++) {
			total = total.add(_totalSharesForToken(_tokens.at(i)));
		}
	}

	function totalSharesFor(address account)
		external
		view
		virtual
		override
		returns (uint256 total)
	{
		EnumerableMap.AddressToUintMap storage staked = _users[account].staked;
		for (uint256 i = 0; i < staked.length(); i++) {
			(address token, uint256 amount) = staked.at(i);
			total = total.add(_shares(token, amount));
		}
	}

	function totalSharesForToken(address token)
		external
		view
		virtual
		override
		returns (uint256)
	{
		return _totalSharesForToken(token);
	}

	function totalStaked(address token)
		public
		view
		virtual
		override
		returns (uint256)
	{
		return _tokenData[token].totalStaked;
	}

	function unredeemableRewards()
		external
		view
		virtual
		override
		returns (uint256)
	{
		return _unredeemableRewards;
	}

	function valuePerTokenImpl(address token)
		public
		view
		virtual
		override
		returns (address)
	{
		return _tokenData[token].valueImpl;
	}

	/* Public Mutators */

	function addToken(address token, address tokenValueImpl)
		external
		virtual
		override
		onlyOwner
	{
		require(!supportsStakingToken(token), "LPRewards: token already added");
		require(
			tokenValueImpl != address(0),
			"LPRewards: tokenValueImpl cannot be zero address"
		);
		_tokens.add(token);
		// Only update implementation in case this was previously used and removed
		_tokenData[token].valueImpl = tokenValueImpl;
		emit TokenAdded(_msgSender(), token, tokenValueImpl);
	}

	function changeTokenValueImpl(address token, address tokenValueImpl)
		external
		virtual
		override
		onlyOwner
		supportsToken(token)
	{
		require(
			tokenValueImpl != address(0),
			"LPRewards: tokenValueImpl cannot be zero address"
		);
		_tokenData[token].valueImpl = tokenValueImpl;
		emit TokenValueImplChanged(_msgSender(), token, tokenValueImpl);
	}

	function exit(bool asWETH) external virtual override {
		unstakeAll();
		redeemAllRewards(asWETH);
	}

	function exitFrom(address token, bool asWETH) external virtual override {
		unstakeAllFrom(token);
		redeemAllRewardsFrom(token, asWETH);
	}

	function pause() external virtual override onlyOwner {
		_pause();
	}

	function recoverUnredeemableRewards(address to, uint256 amount)
		external
		virtual
		override
		onlyOwner
	{
		require(
			amount <= _unredeemableRewards,
			"LPRewards: recovery amount > unredeemable"
		);
		_unredeemableRewards -= amount;
		IERC20(_rewardsToken).safeTransfer(to, amount);
		emit RecoveredUnredeemableRewards(_msgSender(), to, amount);
	}

	function recoverUnstaked(
		address token,
		address to,
		uint256 amount
	) external virtual override onlyOwner {
		require(token != _rewardsToken, "LPRewards: cannot recover rewardsToken");

		uint256 unstaked =
			IERC20(token).balanceOf(address(this)).sub(totalStaked(token));

		require(amount <= unstaked, "LPRewards: recovery amount > unstaked");

		IERC20(token).safeTransfer(to, amount);
		emit RecoveredUnstaked(_msgSender(), token, to, amount);
	}

	function redeemAllRewards(bool asWETH) public virtual override {
		address account = _msgSender();
		_updateAllRewardsFor(account);

		UserData storage user = _users[account];
		EnumerableSet.AddressSet storage tokens = user.tokensWithRewards;
		uint256 redemption = 0;

		for (uint256 length = tokens.length(); length > 0; length--) {
			address token = tokens.at(0);
			TokenData storage td = _tokenData[token];
			UserTokenRewards storage rewards = user.rewardsFor[token];
			uint256 pending = rewards.pending; // Save gas

			redemption += pending;

			rewards.pending = 0;

			td.rewards = td.rewards.sub(pending);
			td.rewardsRedeemed += pending;

			emit RewardPaid(account, token, pending);
			tokens.remove(token);
		}

		_totalRewardsRedeemed += redemption;

		_sendRewards(account, redemption, asWETH);
	}

	function redeemAllRewardsFrom(address token, bool asWETH)
		public
		virtual
		override
	{
		address account = _msgSender();
		_updateRewardFor(account, token);
		uint256 pending = _users[account].rewardsFor[token].pending;
		if (pending != 0) {
			_redeemRewardFrom(token, pending, asWETH);
		}
	}

	function redeemReward(uint256 amount, bool asWETH)
		external
		virtual
		override
	{
		require(amount != 0, "LPRewards: cannot redeem zero");
		address account = _msgSender();
		_updateAllRewardsFor(account);
		require(
			amount <= lastRewardsBalanceOf(account),
			"LPRewards: cannot redeem more rewards than earned"
		);

		UserData storage user = _users[account];
		EnumerableSet.AddressSet storage tokens = user.tokensWithRewards;
		uint256 amountLeft = amount;

		for (uint256 length = tokens.length(); length > 0; length--) {
			address token = tokens.at(0);
			TokenData storage td = _tokenData[token];
			UserTokenRewards storage rewards = user.rewardsFor[token];

			uint256 pending = rewards.pending; // Save gas
			uint256 taken = 0;
			if (pending <= amountLeft) {
				taken = pending;
				tokens.remove(token);
			} else {
				taken = amountLeft;
			}

			rewards.pending = pending - taken;

			td.rewards = td.rewards.sub(taken);
			td.rewardsRedeemed += taken;

			amountLeft -= taken;

			emit RewardPaid(account, token, taken);

			if (amountLeft == 0) {
				break;
			}
		}

		_totalRewardsRedeemed += amount;

		_sendRewards(account, amount, asWETH);
	}

	function redeemRewardFrom(
		address token,
		uint256 amount,
		bool asWETH
	) external virtual override {
		require(amount != 0, "LPRewards: cannot redeem zero");
		address account = _msgSender();
		_updateRewardFor(account, token);
		require(
			amount <= _users[account].rewardsFor[token].pending,
			"LPRewards: cannot redeem more rewards than earned"
		);
		_redeemRewardFrom(token, amount, asWETH);
	}

	function removeToken(address token)
		external
		virtual
		override
		onlyOwner
		supportsToken(token)
	{
		_tokens.remove(token);
		// Clean up. Keep totalStaked and rewards since those will be cleaned up by
		// users unstaking and redeeming.
		_tokenData[token].valueImpl = address(0);
		emit TokenRemoved(_msgSender(), token);
	}

	function setRewardsToken(address token) public virtual override onlyOwner {
		_rewardsToken = token;
		emit RewardsTokenSet(_msgSender(), token);
	}

	function stake(address token, uint256 amount)
		external
		virtual
		override
		whenNotPaused
		supportsToken(token)
	{
		require(amount != 0, "LPRewards: cannot stake zero");

		address account = _msgSender();
		_updateRewardFor(account, token);

		UserData storage user = _users[account];
		TokenData storage td = _tokenData[token];
		td.totalStaked += amount;
		user.staked.set(token, amount + stakedBalanceOf(account, token));

		IERC20(token).safeTransferFrom(account, address(this), amount);
		emit Staked(account, token, amount);
	}

	function unpause() external virtual override onlyOwner {
		_unpause();
	}

	function unstake(address token, uint256 amount) external virtual override {
		require(amount != 0, "LPRewards: cannot unstake zero");

		address account = _msgSender();
		// Prevent making calls to any addresses that were never supported.
		uint256 staked = stakedBalanceOf(account, token);
		require(
			amount <= staked,
			"LPRewards: cannot unstake more than staked balance"
		);

		_unstake(token, amount);
	}

	function unstakeAll() public virtual override {
		UserData storage user = _users[_msgSender()];
		for (uint256 length = user.staked.length(); length > 0; length--) {
			(address token, uint256 amount) = user.staked.at(0);
			_unstake(token, amount);
		}
	}

	function unstakeAllFrom(address token) public virtual override {
		_unstake(token, stakedBalanceOf(_msgSender(), token));
	}

	function updateAccrual() external virtual override {
		// Gas savings
		uint256 totalRewardsAccrued_ = totalRewardsAccrued();
		uint256 pending = totalRewardsAccrued_ - _lastTotalRewardsAccrued;
		if (pending == 0) {
			return;
		}

		_lastTotalRewardsAccrued = totalRewardsAccrued_;

		// Iterate once to know totalShares
		uint256 totalShares_ = 0;
		// Store some math for current shares to save on gas and revert ASAP.
		uint256[] memory pendingSharesFor = new uint256[](_tokens.length());
		for (uint256 i = 0; i < _tokens.length(); i++) {
			uint256 share = _totalSharesForToken(_tokens.at(i));
			pendingSharesFor[i] = pending.mul(share);
			totalShares_ = totalShares_.add(share);
		}

		if (totalShares_ == 0) {
			_unredeemableRewards = _unredeemableRewards.add(pending);
			emit AccrualUpdated(_msgSender(), pending);
			return;
		}

		// Iterate twice to allocate rewards to each token.
		for (uint256 i = 0; i < _tokens.length(); i++) {
			address token = _tokens.at(i);
			TokenData storage td = _tokenData[token];
			td.rewards += pendingSharesFor[i] / totalShares_;
			uint256 rewardsAccrued = totalRewardsAccruedFor(token);
			td.arpt = _accruedRewardsPerTokenFor(token, rewardsAccrued);
			td.lastRewardsAccrued = rewardsAccrued;
		}

		emit AccrualUpdated(_msgSender(), pending);
	}

	function updateReward() external virtual override {
		_updateAllRewardsFor(_msgSender());
	}

	function updateRewardFor(address token) external virtual override {
		_updateRewardFor(_msgSender(), token);
	}

	/* Internal Views */

	function _accruedRewardsPerTokenFor(address token, uint256 rewardsAccrued)
		internal
		view
		virtual
		returns (uint256)
	{
		TokenData storage td = _tokenData[token];
		// Gas savings
		uint256 totalStaked_ = td.totalStaked;

		if (totalStaked_ == 0) {
			return td.arpt;
		}

		// Overflow is OK
		uint256 delta = rewardsAccrued - td.lastRewardsAccrued;
		if (delta == 0) {
			return td.arpt;
		}

		// Use multiplier for better rounding
		uint256 rewardsPerToken = delta.mul(_MULTIPLIER) / totalStaked_;

		// Overflow is OK
		return td.arpt + rewardsPerToken;
	}

	function _allPendingRewardsFor(address account)
		internal
		view
		virtual
		returns (uint256 total)
	{
		EnumerableMap.AddressToUintMap storage staked = _users[account].staked;
		for (uint256 i = 0; i < staked.length(); i++) {
			(address token, uint256 amount) = staked.at(i);
			total += _pendingRewardsFor(account, token, amount);
		}
	}

	function _currentRewardsBalance() internal view virtual returns (uint256) {
		return IERC20(_rewardsToken).balanceOf(address(this));
	}

	function _pendingRewardsFor(
		address account,
		address token,
		uint256 amountStaked
	) internal view virtual returns (uint256) {
		uint256 arpt = accruedRewardsPerTokenFor(token);
		uint256 arptLast = accruedRewardsPerTokenLastFor(account, token);
		// Overflow is OK
		uint256 arptDelta = arpt - arptLast;

		return amountStaked.mul(arptDelta) / _MULTIPLIER;
	}

	function _shares(address token, uint256 amountStaked)
		internal
		view
		virtual
		returns (uint256)
	{
		if (!supportsStakingToken(token)) {
			return 0;
		}
		IValuePerToken vptHandle = IValuePerToken(valuePerTokenImpl(token));
		(uint256 numerator, uint256 denominator) = vptHandle.valuePerToken();
		if (denominator == 0) {
			return 0;
		}
		// Return a 1:1 ratio for value to shares
		return amountStaked.mul(numerator) / denominator;
	}

	function _totalSharesForToken(address token)
		internal
		view
		virtual
		returns (uint256)
	{
		return _shares(token, _tokenData[token].totalStaked);
	}

	/* Internal Mutators */

	function _redeemRewardFrom(
		address token,
		uint256 amount,
		bool asWETH
	) internal virtual {
		address account = _msgSender();
		UserData storage user = _users[account];
		UserTokenRewards storage rewards = user.rewardsFor[token];
		TokenData storage td = _tokenData[token];
		uint256 rewardLeft = rewards.pending - amount;

		rewards.pending = rewardLeft;
		if (rewardLeft == 0) {
			user.tokensWithRewards.remove(token);
		}

		td.rewards = td.rewards.sub(amount);
		td.rewardsRedeemed += amount;

		_totalRewardsRedeemed += amount;

		_sendRewards(account, amount, asWETH);
		emit RewardPaid(account, token, amount);
	}

	function _sendRewards(
		address to,
		uint256 amount,
		bool asWETH
	) internal virtual {
		if (asWETH) {
			IERC20(_rewardsToken).safeTransfer(to, amount);
		} else {
			IWETH(_rewardsToken).withdraw(amount);
			payable(to).sendValue(amount);
		}
	}

	function _unstake(address token, uint256 amount) internal virtual {
		address account = _msgSender();

		_updateRewardFor(account, token);

		TokenData storage td = _tokenData[token];
		td.totalStaked = td.totalStaked.sub(amount);

		UserData storage user = _users[account];
		EnumerableMap.AddressToUintMap storage staked = user.staked;

		uint256 stakeLeft = staked.get(token).sub(amount);
		if (stakeLeft == 0) {
			staked.remove(token);
			user.rewardsFor[token].arptLast = 0;
		} else {
			staked.set(token, stakeLeft);
		}

		IERC20(token).safeTransfer(account, amount);
		emit Unstaked(account, token, amount);
	}

	function _updateRewardFor(address account, address token)
		internal
		virtual
		returns (uint256)
	{
		UserData storage user = _users[account];
		UserTokenRewards storage rewards = user.rewardsFor[token];
		uint256 total = rewards.pending; // Save gas
		uint256 amountStaked = stakedBalanceOf(account, token);
		uint256 pending = _pendingRewardsFor(account, token, amountStaked);
		if (pending != 0) {
			total += pending;
			rewards.pending = total;
			user.tokensWithRewards.add(token);
		}
		rewards.arptLast = accruedRewardsPerTokenFor(token);
		return total;
	}

	function _updateAllRewardsFor(address account) internal virtual {
		EnumerableMap.AddressToUintMap storage staked = _users[account].staked;
		for (uint256 i = 0; i < staked.length(); i++) {
			(address token, ) = staked.at(i);
			_updateRewardFor(account, token);
		}
	}
}

