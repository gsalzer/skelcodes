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

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./ETHtxData.sol";
import "../ERC20/ERC20Data.sol";
import "../ERC20TxFee/ERC20TxFeeData.sol";
import "../interfaces/IERC20Metadata.sol";
import "../interfaces/IETHtx.sol";
import "../../rewards/interfaces/IFeeLogic.sol";
import "../../access/RbacFromOwnable/RbacFromOwnable.sol";

/* solhint-disable not-rely-on-time */

contract ETHtx is
	Initializable,
	ContextUpgradeable,
	RbacFromOwnable,
	PausableUpgradeable,
	ERC20Data,
	ERC20TxFeeData,
	ETHtxData,
	IERC20,
	IERC20Metadata,
	IETHtx
{
	using SafeERC20 for IERC20;
	using SafeMath for uint256;

	struct ETHtxArgs {
		address feeLogic;
		address[] minters;
		address[] rebasers;
	}

	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
	bytes32 public constant REBASER_ROLE = keccak256("REBASER_ROLE");

	uint256 internal constant _SHARES_MULT = 1e18;

	/* Constructor */

	constructor(address owner_) {
		init(owner_);
	}

	/* Initializer */

	function init(address owner_) public virtual initializer {
		__Context_init_unchained();
		__Pausable_init_unchained();
		_setupRole(DEFAULT_ADMIN_ROLE, owner_);
	}

	function postInit(ETHtxArgs memory _args)
		external
		virtual
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		address sender = _msgSender();

		_feeLogic = _args.feeLogic;
		emit FeeLogicSet(sender, _args.feeLogic);

		for (uint256 i = 0; i < _args.minters.length; i++) {
			_setupRole(MINTER_ROLE, _args.minters[i]);
		}

		for (uint256 i = 0; i < _args.rebasers.length; i++) {
			_setupRole(REBASER_ROLE, _args.rebasers[i]);
		}

		_sharesPerToken = _SHARES_MULT;
	}

	function postUpgrade(address feeLogic_, address[] memory rebasers)
		external
		virtual
	{
		address sender = _msgSender();
		// Can only be called once
		require(
			_ownerDeprecated == sender,
			"ETHtx::postUpgrade: caller is not the owner"
		);

		_feeLogic = feeLogic_;
		emit FeeLogicSet(sender, feeLogic_);

		// Set sharesPerToken to 1:1
		_totalShares = _totalSupply;
		_sharesPerToken = _SHARES_MULT;

		// Setup RBAC
		_setupRole(DEFAULT_ADMIN_ROLE, sender);
		_setupRole(MINTER_ROLE, _minterDeprecated);
		for (uint256 i = 0; i < rebasers.length; i++) {
			_setupRole(REBASER_ROLE, rebasers[i]);
		}

		// Clear deprecated state
		_minterDeprecated = address(0);
		_ownerDeprecated = address(0);
	}

	/* External Mutators */

	function transfer(address recipient, uint256 amount)
		public
		virtual
		override
		returns (bool)
	{
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) public virtual override returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(
			sender,
			_msgSender(),
			_allowances[sender][_msgSender()].sub(
				amount,
				"ETHtx::transferFrom: amount exceeds allowance"
			)
		);
		return true;
	}

	function approve(address spender, uint256 amount)
		public
		virtual
		override
		returns (bool)
	{
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue)
		public
		virtual
		returns (bool)
	{
		_approve(
			_msgSender(),
			spender,
			_allowances[_msgSender()][spender].add(addedValue)
		);
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue)
		public
		virtual
		returns (bool)
	{
		_approve(
			_msgSender(),
			spender,
			_allowances[_msgSender()][spender].sub(
				subtractedValue,
				"ETHtx::decreaseAllowance: below zero"
			)
		);
		return true;
	}

	function burn(address account, uint256 amount)
		external
		virtual
		override
		onlyRole(MINTER_ROLE)
		whenNotPaused
	{
		_burn(account, amount);
	}

	function mint(address account, uint256 amount)
		external
		virtual
		override
		onlyRole(MINTER_ROLE)
		whenNotPaused
	{
		_mint(account, amount);
	}

	function pause()
		external
		virtual
		override
		onlyRole(DEFAULT_ADMIN_ROLE)
		whenNotPaused
	{
		_pause();
	}

	function rebase()
		external
		virtual
		override
		onlyRole(REBASER_ROLE)
		whenNotPaused
	{
		// Limit calls
		uint256 timePassed =
			block.timestamp.sub(
				_lastRebaseTime,
				"ETHtx::rebase: block is older than last rebase"
			);
		IFeeLogic feeHandle = IFeeLogic(_feeLogic);
		require(
			timePassed >= feeHandle.rebaseInterval(),
			"ETHtx::rebase: too soon"
		);

		uint256 initTotalShares = _totalShares;
		if (initTotalShares == 0) {
			return;
		}

		(uint128 rebaseNum, uint128 rebaseDen) = feeHandle.rebaseFeeRate();

		// WARN This will eventually overflow
		uint256 ts = initTotalShares.mul(rebaseDen) / (rebaseDen - rebaseNum);
		uint256 newShares = ts - initTotalShares;

		// Send to exemptions to return them to their initial percentage
		for (uint256 i = 0; i < feeHandle.rebaseExemptsLength(); i++) {
			address exempt = feeHandle.rebaseExemptsAt(i);
			uint256 balance = _balances[exempt];
			if (balance != 0) {
				uint256 newBalance = balance.mul(rebaseDen) / (rebaseDen - rebaseNum);
				uint256 addedShares = newBalance - balance;
				_balances[exempt] = newBalance;
				newShares -= addedShares;
			}
		}
		assert(newShares < ts);

		// Send the remainder to rewards
		address rewardsRecipient = feeHandle.recipient();
		_balances[rewardsRecipient] = _balances[rewardsRecipient].add(newShares);

		// Mint shares, reducing every holder's percentage
		_totalShares = ts;
		// WARN This will eventually overflow
		_sharesPerToken = ts.mul(_SHARES_MULT).div(_totalSupply);

		_lastRebaseTime = block.timestamp;

		emit Rebased(_msgSender(), ts);
	}

	function recoverERC20(
		address token,
		address to,
		uint256 amount
	) external virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
		IERC20(token).safeTransfer(to, amount);
		emit Recovered(_msgSender(), token, to, amount);
	}

	function setFeeLogic(address account)
		external
		virtual
		override
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		require(account != address(0), "ETHtx::setFeeLogic: zero address");
		_feeLogic = account;
		emit FeeLogicSet(_msgSender(), account);
	}

	function unpause()
		external
		virtual
		override
		onlyRole(DEFAULT_ADMIN_ROLE)
		whenPaused
	{
		_unpause();
	}

	/* External Views */

	function allowance(address owner, address spender)
		public
		view
		virtual
		override
		returns (uint256)
	{
		return _allowances[owner][spender];
	}

	function balanceOf(address account)
		public
		view
		virtual
		override
		returns (uint256)
	{
		return _balances[account].mul(_SHARES_MULT).div(_sharesPerToken);
	}

	function sharesBalanceOf(address account)
		public
		view
		virtual
		override
		returns (uint256)
	{
		return _balances[account];
	}

	function name() public view virtual override returns (string memory) {
		return "Ethereum Transaction";
	}

	function symbol() public view virtual override returns (string memory) {
		return "ETHtx";
	}

	function decimals() public view virtual override returns (uint8) {
		return 18;
	}

	function feeLogic() public view virtual override returns (address) {
		return _feeLogic;
	}

	function lastRebaseTime() public view virtual override returns (uint256) {
		return _lastRebaseTime;
	}

	function sharesPerTokenX18()
		external
		view
		virtual
		override
		returns (uint256)
	{
		return _sharesPerToken;
	}

	function totalShares() public view virtual override returns (uint256) {
		return _totalShares;
	}

	function totalSupply() public view virtual override returns (uint256) {
		return _totalSupply;
	}

	/* Internal Mutators */

	function _approve(
		address owner,
		address spender,
		uint256 amount
	) internal virtual {
		require(owner != address(0), "ETHtx::_approve: from the zero address");
		require(spender != address(0), "ETHtx::_approve: to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	/**
	 * @dev Implements an ERC20 transfer with a fee.
	 *
	 * Emits a {Transfer} event. Emits a second {Transfer} event for the fee.
	 *
	 * Requirements:
	 *
	 * - `sender` cannot be the zero address.
	 * - `recipient` cannot be the zero address.
	 * - `sender` must have a balance of at least `amount`.
	 * - `_feeLogic` implements {IFeeLogic}
	 */
	function _transfer(
		address sender,
		address recipient,
		uint256 amount
	) internal virtual {
		require(sender != address(0), "ETHtx::_transfer: from the zero address");
		require(recipient != address(0), "ETHtx::_transfer: to the zero address");

		uint256 spt = _sharesPerToken;
		require(spt != 0, "ETHtx::_transfer: zero sharesPerToken");

		// Could round small values to zero
		uint256 shares = amount.mul(spt).div(_SHARES_MULT);

		_balances[sender] = _balances[sender].sub(
			shares,
			"ETHtx::_transfer: amount exceeds balance"
		);

		IFeeLogic feeHandler = IFeeLogic(_feeLogic);
		uint256 fee = feeHandler.getFee(sender, recipient, shares);
		uint256 sharesSubFee = shares.sub(fee);

		_balances[recipient] = _balances[recipient].add(sharesSubFee);
		emit Transfer(sender, recipient, (sharesSubFee * _SHARES_MULT) / spt);

		if (fee != 0) {
			address feeRecipient = feeHandler.recipient();
			_balances[feeRecipient] = _balances[feeRecipient].add(fee);

			uint256 feeInTokens = (fee * _SHARES_MULT) / spt;
			emit Transfer(sender, feeRecipient, feeInTokens);
			feeHandler.notify(feeInTokens);
		}
	}

	function _burn(address account, uint256 amount) internal {
		// Burn shares proportionately for constant _sharesPerToken
		uint256 shares = amount.mul(_sharesPerToken) / _SHARES_MULT;
		_balances[account] = _balances[account].sub(
			shares,
			"ETHtx::_burn: amount exceeds balance"
		);
		_totalShares = _totalShares.sub(shares);
		// Burn tokens
		_totalSupply = _totalSupply.sub(amount);

		emit Transfer(account, address(0), amount);
	}

	function _mint(address account, uint256 amount) internal {
		// Mint shares proportionately for constant _sharesPerToken
		uint256 shares = amount.mul(_sharesPerToken) / _SHARES_MULT;
		_totalShares = _totalShares.add(shares);
		_balances[account] = _balances[account].add(shares);
		// Mint tokens
		_totalSupply = _totalSupply.add(amount);

		emit Transfer(address(0), account, amount);
	}
}

