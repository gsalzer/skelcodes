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

import "./ETHtxData.sol";
import "../ERC20TxFee/ERC20TxFeeUpgradeable.sol";
import "../interfaces/IETHtx.sol";
import "../../access/OwnableUpgradeable.sol";

contract ETHtx is
	Initializable,
	ContextUpgradeable,
	OwnableUpgradeable,
	PausableUpgradeable,
	ERC20TxFeeUpgradeable,
	ETHtxData,
	IETHtx
{
	using SafeERC20 for IERC20;

	struct ETHtxArgs {
		address feeLogic;
		address minter;
	}

	/* Constructor */

	constructor(address owner_) {
		init(owner_);
	}

	/* Initializer */

	function init(address owner_) public virtual initializer {
		__Context_init_unchained();
		__Ownable_init_unchained(owner_);
		__Pausable_init_unchained();
	}

	function postInit(ETHtxArgs memory _args) external virtual onlyOwner {
		address sender = _msgSender();

		_feeLogic = _args.feeLogic;
		emit FeeLogicSet(sender, _args.feeLogic);

		_minter = _args.minter;
		emit MinterSet(sender, _args.minter);
	}

	/* Modifiers */

	modifier onlyMinter {
		require(_msgSender() == minter(), "ETHtx: caller is not the minter");
		_;
	}

	/* External Mutators */

	function burn(address account, uint256 amount)
		external
		virtual
		override
		onlyMinter
		whenNotPaused
	{
		_burn(account, amount);
	}

	function mint(address account, uint256 amount)
		external
		virtual
		override
		onlyMinter
		whenNotPaused
	{
		_mint(account, amount);
	}

	function pause() external virtual override onlyOwner whenNotPaused {
		_pause();
	}

	function recoverERC20(
		address token,
		address to,
		uint256 amount
	) external virtual override onlyOwner {
		IERC20(token).safeTransfer(to, amount);
		emit Recovered(_msgSender(), token, to, amount);
	}

	function setFeeLogic(address account) external virtual override onlyOwner {
		require(account != address(0), "ETHtx: feeLogic zero address");
		_feeLogic = account;
		emit FeeLogicSet(_msgSender(), account);
	}

	function setMinter(address account) external virtual override onlyOwner {
		_minter = account;
		emit MinterSet(_msgSender(), account);
	}

	function unpause() external virtual override onlyOwner whenPaused {
		_unpause();
	}

	/* External Views */

	function minter() public view virtual override returns (address) {
		return _minter;
	}

	function name() public view virtual override returns (string memory) {
		return "Ethereum Transaction";
	}

	function symbol() public view virtual override returns (string memory) {
		return "ETHtx";
	}
}

