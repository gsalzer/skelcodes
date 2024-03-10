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

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import "../ERC20/ERC20Upgradeable.sol";
import "../interfaces/IERC20TxFee.sol";
import "../../rewards/interfaces/IFeeLogic.sol";

contract ERC20TxFeeUpgradeable is
	Initializable,
	ContextUpgradeable,
	ERC20Upgradeable,
	IERC20TxFee
{
	using SafeMath for uint256;

	/* Mutable Internal State */

	address internal _feeLogic;

	// solhint-disable-next-line func-name-mixedcase
	function __ERC20TxFee_init(address feeLogic_) internal initializer {
		__ERC20_init();
		__ERC20TxFee_init_unchained(feeLogic_);
	}

	// solhint-disable-next-line func-name-mixedcase
	function __ERC20TxFee_init_unchained(address feeLogic_)
		internal
		initializer
	{
		require(feeLogic_ != address(0), "ERC20TxFee: feeLogic zero address");
		__ERC20_init_unchained();
		_feeLogic = feeLogic_;
	}

	/* Public Views */

	/**
	 * @dev Returns the feeLogic handler address.
	 */
	function feeLogic() public view virtual override returns (address) {
		return _feeLogic;
	}

	/* Internal Mutators */

	/**
	 * @dev Overrides {ERC20-_transfer} to implement a fee on transfers.
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
	) internal virtual override {
		require(sender != address(0), "ERC20: transfer from the zero address");
		require(recipient != address(0), "ERC20: transfer to the zero address");

		_beforeTokenTransfer(sender, recipient, amount);

		_balances[sender] = _balances[sender].sub(
			amount,
			"ERC20: transfer amount exceeds balance"
		);

		IFeeLogic feeHandler = IFeeLogic(_feeLogic);
		uint256 fee = feeHandler.getFee(sender, recipient, amount);
		uint256 amountSubFee = amount.sub(fee);

		_balances[recipient] = _balances[recipient].add(amountSubFee);
		emit Transfer(sender, recipient, amountSubFee);

		if (fee != 0) {
			address feeRecipient = feeHandler.recipient();
			_balances[feeRecipient] = _balances[feeRecipient].add(fee);
			emit Transfer(sender, feeRecipient, fee);
			feeHandler.notify(fee);
		}
	}

	uint256[49] private __gap;
}

