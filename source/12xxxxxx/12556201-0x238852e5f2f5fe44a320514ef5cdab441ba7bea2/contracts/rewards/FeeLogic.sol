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

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/IFeeLogic.sol";
import "../access/Ownable.sol";

contract FeeLogic is Ownable, IFeeLogic {
	using EnumerableSet for EnumerableSet.AddressSet;
	using SafeMath for uint128;
	using SafeMath for uint256;

	struct FeeLogicArgs {
		address owner;
		address recipient;
		uint128 feeRateNumerator;
		uint128 feeRateDenominator;
		ExemptData[] exemptions;
		uint256 rebaseInterval;
		uint128 rebaseFeeRateNum;
		uint128 rebaseFeeRateDen;
		ExemptData[] rebaseExemptions;
	}

	/* Mutable Private State */

	EnumerableSet.AddressSet private _exempts;
	uint128 private _feeRateNum;
	uint128 private _feeRateDen;
	address private _recipient;

	EnumerableSet.AddressSet private _rebaseExempts;
	uint256 private _rebaseInterval;
	uint128 private _rebaseFeeRateNum;
	uint128 private _rebaseFeeRateDen;

	/* Constructor */

	constructor(FeeLogicArgs memory _args) Ownable(_args.owner) {
		require(
			_args.feeRateDenominator > _args.feeRateNumerator,
			"FeeLogic: feeRate is gte to 1"
		);
		require(
			_args.rebaseFeeRateDen > _args.rebaseFeeRateNum,
			"FeeLogic: rebaseFeeRate is gte to 1"
		);

		address sender = _msgSender();

		_recipient = _args.recipient;
		emit RecipientSet(sender, _args.recipient);
		_feeRateNum = _args.feeRateNumerator;
		_feeRateDen = _args.feeRateDenominator;
		emit FeeRateSet(sender, _args.feeRateNumerator, _args.feeRateDenominator);

		for (uint256 i = 0; i < _args.exemptions.length; i++) {
			address account = _args.exemptions[i].account;
			if (_args.exemptions[i].isExempt) {
				if (_exempts.add(account)) {
					emit ExemptAdded(sender, account);
				}
			} else if (_exempts.remove(account)) {
				emit ExemptRemoved(sender, account);
			}
		}

		_rebaseInterval = _args.rebaseInterval;
		emit RebaseIntervalSet(sender, _args.rebaseInterval);

		_rebaseFeeRateNum = _args.rebaseFeeRateNum;
		_rebaseFeeRateDen = _args.rebaseFeeRateDen;
		emit RebaseFeeRateSet(
			sender,
			_args.rebaseFeeRateNum,
			_args.rebaseFeeRateDen
		);

		for (uint256 i = 0; i < _args.rebaseExemptions.length; i++) {
			address account = _args.rebaseExemptions[i].account;
			if (_args.rebaseExemptions[i].isExempt) {
				if (_rebaseExempts.add(account)) {
					emit RebaseExemptAdded(sender, account);
				}
			} else if (_rebaseExempts.remove(account)) {
				emit RebaseExemptRemoved(sender, account);
			}
		}
	}

	/* External Views */

	function exemptsAt(uint256 index)
		external
		view
		virtual
		override
		returns (address)
	{
		return _exempts.at(index);
	}

	function exemptsLength() external view virtual override returns (uint256) {
		return _exempts.length();
	}

	function feeRate()
		external
		view
		virtual
		override
		returns (uint128 numerator, uint128 denominator)
	{
		numerator = _feeRateNum;
		denominator = _feeRateDen;
	}

	function getFee(
		address sender,
		address, /* recipient_ */
		uint256 amount
	) external view virtual override returns (uint256) {
		if (_exempts.contains(sender)) {
			return 0;
		}
		return amount.mul(_feeRateNum) / _feeRateDen;
	}

	function getRebaseFee(uint256 amount)
		external
		view
		virtual
		override
		returns (uint256)
	{
		return amount.mul(_rebaseFeeRateNum) / _rebaseFeeRateDen;
	}

	function isExempt(address account)
		external
		view
		virtual
		override
		returns (bool)
	{
		return _exempts.contains(account);
	}

	function isRebaseExempt(address account)
		external
		view
		virtual
		override
		returns (bool)
	{
		return _rebaseExempts.contains(account);
	}

	function rebaseExemptsAt(uint256 index)
		external
		view
		virtual
		override
		returns (address)
	{
		return _rebaseExempts.at(index);
	}

	function rebaseExemptsLength()
		external
		view
		virtual
		override
		returns (uint256)
	{
		return _rebaseExempts.length();
	}

	function rebaseFeeRate()
		external
		view
		virtual
		override
		returns (uint128 numerator, uint128 denominator)
	{
		numerator = _rebaseFeeRateNum;
		denominator = _rebaseFeeRateDen;
	}

	function rebaseInterval() external view virtual override returns (uint256) {
		return _rebaseInterval;
	}

	function recipient() external view virtual override returns (address) {
		return _recipient;
	}

	function undoFee(
		address sender,
		address, /* recipient_ */
		uint256 amount
	) external view virtual override returns (uint256) {
		if (_exempts.contains(sender)) {
			return amount;
		}
		return amount.mul(_feeRateDen) / (_feeRateDen - _feeRateNum);
	}

	function undoRebaseFee(uint256 amount)
		external
		view
		virtual
		override
		returns (uint256)
	{
		return
			amount.mul(_rebaseFeeRateDen) / (_rebaseFeeRateDen - _rebaseFeeRateNum);
	}

	/* External Mutators */

	function notify(
		uint256 /* amount */
	) external virtual override {
		return;
	}

	function setExempt(address account, bool isExempt_)
		public
		virtual
		override
		onlyOwner
	{
		if (isExempt_) {
			if (_exempts.add(account)) {
				emit ExemptAdded(_msgSender(), account);
			}
			return;
		}
		if (_exempts.remove(account)) {
			emit ExemptRemoved(_msgSender(), account);
		}
	}

	function setExemptBatch(ExemptData[] memory batch)
		public
		virtual
		override
		onlyOwner
	{
		for (uint256 i = 0; i < batch.length; i++) {
			setExempt(batch[i].account, batch[i].isExempt);
		}
	}

	function setFeeRate(uint128 numerator, uint128 denominator)
		external
		virtual
		override
		onlyOwner
	{
		// Also guarantees that the denominator cannot be zero.
		require(denominator > numerator, "FeeLogic: feeRate is gte to 1");
		_feeRateNum = numerator;
		_feeRateDen = denominator;
		emit FeeRateSet(_msgSender(), numerator, denominator);
	}

	function setRebaseExempt(address account, bool isExempt_)
		public
		virtual
		override
		onlyOwner
	{
		if (isExempt_) {
			if (_rebaseExempts.add(account)) {
				emit RebaseExemptAdded(_msgSender(), account);
			}
			return;
		}
		if (_rebaseExempts.remove(account)) {
			emit RebaseExemptRemoved(_msgSender(), account);
		}
	}

	function setRebaseExemptBatch(ExemptData[] memory batch)
		public
		virtual
		override
		onlyOwner
	{
		for (uint256 i = 0; i < batch.length; i++) {
			setRebaseExempt(batch[i].account, batch[i].isExempt);
		}
	}

	function setRebaseFeeRate(uint128 numerator, uint128 denominator)
		external
		virtual
		override
		onlyOwner
	{
		// Also guarantees that the denominator cannot be zero.
		require(denominator > numerator, "FeeLogic: rebaseFeeRate is gte to 1");
		_rebaseFeeRateNum = numerator;
		_rebaseFeeRateDen = denominator;
		emit RebaseFeeRateSet(_msgSender(), numerator, denominator);
	}

	function setRebaseInterval(uint256 interval)
		external
		virtual
		override
		onlyOwner
	{
		_rebaseInterval = interval;
		emit RebaseIntervalSet(_msgSender(), interval);
	}

	function setRecipient(address account) external virtual override onlyOwner {
		require(account != address(0), "FeeLogic: recipient is zero address");
		_recipient = account;
		emit RecipientSet(_msgSender(), account);
	}
}

