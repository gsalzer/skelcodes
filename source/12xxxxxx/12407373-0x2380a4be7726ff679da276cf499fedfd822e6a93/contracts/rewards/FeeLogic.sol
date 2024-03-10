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

	/* Mutable Private State */

	EnumerableSet.AddressSet private _exempts;
	uint128 private _feeRateNum;
	uint128 private _feeRateDen;
	address private _recipient;

	/* Constructor */

	constructor(
		address owner_,
		address recipient_,
		uint128 feeRateNumerator,
		uint128 feeRateDenominator,
		ExemptData[] memory exemptions
	) Ownable(owner_) {
		address sender = _msgSender();

		_recipient = recipient_;
		emit RecipientSet(sender, recipient_);

		_feeRateNum = feeRateNumerator;
		_feeRateDen = feeRateDenominator;
		emit FeeRateSet(sender, feeRateNumerator, feeRateDenominator);

		for (uint256 i = 0; i < exemptions.length; i++) {
			address account = exemptions[i].account;
			if (exemptions[i].isExempt && _exempts.add(account)) {
				emit ExemptAdded(sender, account);
			} else if (_exempts.remove(account)) {
				emit ExemptRemoved(sender, account);
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
		return amount.mul(_feeRateNum).div(_feeRateDen);
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
		return amount.mul(_feeRateDen).div(_feeRateDen - _feeRateNum);
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

	function setRecipient(address account) external virtual override onlyOwner {
		require(account != address(0), "FeeLogic: recipient is zero address");
		_recipient = account;
		emit RecipientSet(_msgSender(), account);
	}
}

