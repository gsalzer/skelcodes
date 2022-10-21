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

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./ETHtxAMMData.sol";
import "../interfaces/IETHtxAMM.sol";
import "../../tokens/interfaces/IETHmx.sol";
import "../../tokens/interfaces/IETHtx.sol";
import "../../tokens/interfaces/IERC20TxFee.sol";
import "../../tokens/interfaces/IWETH.sol";
import "../../rewards/interfaces/IFeeLogic.sol";
import "../../oracles/interfaces/IGasPrice.sol";
import "../../access/OwnableUpgradeable.sol";

contract ETHtxAMM is
	Initializable,
	ContextUpgradeable,
	OwnableUpgradeable,
	PausableUpgradeable,
	ETHtxAMMData,
	IETHtxAMM
{
	using Address for address payable;
	using SafeERC20 for IERC20;
	using SafeMath for uint128;
	using SafeMath for uint256;

	struct ETHtxAMMArgs {
		address ethtx;
		address gasOracle;
		address weth;
		uint128 targetCRatioNum;
		uint128 targetCRatioDen;
		address ethmx;
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

	function postInit(ETHtxAMMArgs memory _args) external virtual onlyOwner {
		address sender = _msgSender();

		_ethtx = _args.ethtx;
		emit ETHtxSet(sender, _args.ethtx);

		_gasOracle = _args.gasOracle;
		emit GasOracleSet(sender, _args.gasOracle);

		_weth = _args.weth;
		emit WETHSet(sender, _args.weth);

		_targetCRatioNum = _args.targetCRatioNum;
		_targetCRatioDen = _args.targetCRatioDen;
		emit TargetCRatioSet(sender, _args.targetCRatioNum, _args.targetCRatioDen);

		_ethmx = _args.ethmx;
		emit ETHmxSet(sender, _args.ethmx);
	}

	/* Fallbacks */

	receive() external payable {
		// Only accept ETH via fallback from the WETH contract
		address weth_ = weth();
		if (msg.sender != weth_) {
			// Otherwise try to convert it to WETH
			IWETH(weth_).deposit{ value: msg.value }();
		}
	}

	/* Modifiers */

	modifier ensure(uint256 deadline) {
		// solhint-disable-next-line not-rely-on-time
		require(deadline >= block.timestamp, "ETHtxAMM: expired");
		_;
	}

	modifier priceIsFresh() {
		require(
			!IGasPrice(gasOracle()).hasPriceExpired(),
			"ETHtxAMM: gas price is outdated"
		);
		_;
	}

	/* External Mutators */

	function swapEthForEthtx(uint256 deadline)
		external
		payable
		virtual
		override
	{
		_swapEthForEthtxRaw(msg.value, deadline, false);
	}

	function swapWethForEthtx(uint256 amountIn, uint256 deadline)
		external
		virtual
		override
	{
		_swapEthForEthtxRaw(amountIn, deadline, true);
	}

	function swapEthForExactEthtx(uint256 amountOut, uint256 deadline)
		external
		payable
		virtual
		override
	{
		uint256 amountInMax = msg.value;
		uint256 amountIn =
			_swapEthForExactEthtx(amountInMax, amountOut, deadline, false);
		// refund leftover ETH
		if (amountInMax != amountIn) {
			payable(_msgSender()).sendValue(amountInMax - amountIn);
		}
	}

	function swapWethForExactEthtx(
		uint256 amountInMax,
		uint256 amountOut,
		uint256 deadline
	) external virtual override {
		_swapEthForExactEthtx(amountInMax, amountOut, deadline, true);
	}

	function swapExactEthForEthtx(uint256 amountOutMin, uint256 deadline)
		external
		payable
		virtual
		override
	{
		_swapExactEthForEthtx(msg.value, amountOutMin, deadline, false);
	}

	function swapExactWethForEthtx(
		uint256 amountIn,
		uint256 amountOutMin,
		uint256 deadline
	) external virtual override {
		_swapExactEthForEthtx(amountIn, amountOutMin, deadline, true);
	}

	function swapEthtxForEth(
		uint256 amountIn,
		uint256 deadline,
		bool asWETH
	) external virtual override ensure(deadline) priceIsFresh {
		require(amountIn != 0, "ETHtxAMM: cannot swap zero");
		uint256 amountOut = exactEthtxToEth(amountIn);
		_swapEthtxForEth(_msgSender(), amountIn, amountOut, asWETH);
	}

	function swapEthtxForExactEth(
		uint256 amountInMax,
		uint256 amountOut,
		uint256 deadline,
		bool asWETH
	) external virtual override ensure(deadline) priceIsFresh {
		require(amountInMax != 0, "ETHtxAMM: cannot swap zero");
		uint256 amountIn = ethtxToExactEth(amountOut);
		require(amountIn <= amountInMax, "ETHtxAMM: amountIn exceeds max");
		_swapEthtxForEth(_msgSender(), amountIn, amountOut, asWETH);
	}

	function swapExactEthtxForEth(
		uint256 amountIn,
		uint256 amountOutMin,
		uint256 deadline,
		bool asWETH
	) external virtual override ensure(deadline) priceIsFresh {
		require(amountIn != 0, "ETHtxAMM: cannot swap zero");
		uint256 amountOut = exactEthtxToEth(amountIn);
		require(amountOut >= amountOutMin, "ETHtxAMM: amountOut below min");
		_swapEthtxForEth(_msgSender(), amountIn, amountOut, asWETH);
	}

	function burnETHmx(uint256 amount, bool asWETH)
		external
		virtual
		override
		whenNotPaused
	{
		address account = _msgSender();
		uint256 ethmxSupply = IERC20(ethmx()).totalSupply();
		require(ethmxSupply != 0, "ETHtxAMM: no ETHmx supply");
		require(amount != 0, "ETHtxAMM: zero amount");

		// Calculate percentage of ETH and ETHtx.
		uint256 initETH = (ethSupply().sub(_geth)).mul(amount).div(ethmxSupply);
		uint256 amountETH = initETH.mul(6).div(10);
		_geth = _geth.add(initETH.sub(amountETH));
		uint256 amountETHtx =
			IERC20(ethtx()).totalSupply().mul(amount).div(ethmxSupply);

		// Burn ETHmx (ETHmx doesn't have a burnFrom function)
		IERC20(ethmx()).transferFrom(account, address(this), amount);
		IETHmx(ethmx()).burn(amount);

		// Burn ETHtx
		IETHtx(ethtx()).burn(address(this), amountETHtx);

		// Send ETH
		if (asWETH) {
			IERC20(weth()).safeTransfer(account, amountETH);
		} else {
			IWETH(weth()).withdraw(amountETH);
			payable(account).sendValue(amountETH);
		}

		emit BurnedETHmx(account, amount);
	}

	function pause() external virtual override onlyOwner whenNotPaused {
		_pause();
	}

	function recoverUnsupportedERC20(
		address token,
		address to,
		uint256 amount
	) external virtual override onlyOwner {
		require(token != weth(), "ETHtxAMM: cannot recover WETH");
		require(token != ethtx(), "ETHtxAMM: cannot recover ETHtx");

		IERC20(token).safeTransfer(to, amount);
		emit RecoveredUnsupported(_msgSender(), token, to, amount);
	}

	function setEthmx(address account) public virtual override onlyOwner {
		require(account != address(0), "ETHtxAMM: ETHmx zero address");
		_ethmx = account;
		emit ETHmxSet(_msgSender(), account);
	}

	function setEthtx(address account) public virtual override onlyOwner {
		require(account != address(0), "ETHtxAMM: ETHtx zero address");
		_ethtx = account;
		emit ETHtxSet(_msgSender(), account);
	}

	function setGasOracle(address account) public virtual override onlyOwner {
		require(account != address(0), "ETHtxAMM: gasOracle zero address");
		_gasOracle = account;
		emit GasOracleSet(_msgSender(), account);
	}

	function setGeth(uint256 amount) public virtual override onlyOwner {
		_geth = amount;
		emit GethSet(_msgSender(), amount);
	}

	function setTargetCRatio(uint128 numerator, uint128 denominator)
		public
		virtual
		override
		onlyOwner
	{
		require(numerator != 0, "ETHtxAMM: targetCRatio numerator is zero");
		require(denominator != 0, "ETHtxAMM: targetCRatio denominator is zero");
		_targetCRatioNum = numerator;
		_targetCRatioDen = denominator;
		emit TargetCRatioSet(_msgSender(), numerator, denominator);
	}

	function setWETH(address account) public virtual override onlyOwner {
		require(account != address(0), "ETHtxAMM: WETH zero address");
		_weth = account;
		emit WETHSet(_msgSender(), account);
	}

	function unpause() external virtual override onlyOwner whenPaused {
		_unpause();
	}

	/* Public Pure */

	function gasPerETHtx() public pure virtual override returns (uint256) {
		return 21000; // Per 1e18
	}

	/* Public Views */

	function cRatio()
		public
		view
		virtual
		override
		returns (uint256 numerator, uint256 denominator)
	{
		numerator = ethSupply();
		denominator = ethToExactEthtx(ethtxOutstanding());
	}

	function cRatioBelowTarget() public view virtual override returns (bool) {
		(uint256 cRatioNum, uint256 cRatioDen) = cRatio();
		if (cRatioDen == 0) {
			return false;
		}

		uint256 current = cRatioNum.mul(1e18) / cRatioDen;

		(uint256 targetNum, uint256 targetDen) = targetCRatio();
		uint256 target = targetNum.mul(1e18).div(targetDen);

		return current < target;
	}

	function ethNeeded() external view virtual override returns (uint256) {
		(uint256 ethSupply_, uint256 ethOut) = cRatio();
		(uint128 targetNum, uint128 targetDen) = targetCRatio();

		uint256 target = ethOut.mul(targetNum).div(targetDen);

		if (ethSupply_ > target) {
			return 0;
		}

		return target - ethSupply_;
	}

	function ethmx() public view virtual override returns (address) {
		return _ethmx;
	}

	function ethtx() public view virtual override returns (address) {
		return _ethtx;
	}

	function exactEthToEthtx(uint256 amountEthIn)
		public
		view
		virtual
		override
		returns (uint256)
	{
		return _ethToEthtx(gasPrice(), amountEthIn);
	}

	function ethToExactEthtx(uint256 amountEthtxOut)
		public
		view
		virtual
		override
		returns (uint256)
	{
		return _ethtxToEth(gasPrice(), amountEthtxOut);
	}

	function exactEthtxToEth(uint256 amountEthtxIn)
		public
		view
		virtual
		override
		returns (uint256)
	{
		// Account for fee
		uint256 fee =
			IFeeLogic(feeLogic()).getFee(_msgSender(), address(this), amountEthtxIn);

		return _ethtxToEth(gasPriceAtRedemption(), amountEthtxIn.sub(fee));
	}

	function ethtxToExactEth(uint256 amountEthOut)
		public
		view
		virtual
		override
		returns (uint256)
	{
		uint256 amountEthtx = _ethToEthtx(gasPriceAtRedemption(), amountEthOut);

		// Account for fee
		uint256 amountBeforeFee =
			IFeeLogic(feeLogic()).undoFee(_msgSender(), address(this), amountEthtx);

		return amountBeforeFee;
	}

	function ethSupply() public view virtual override returns (uint256) {
		return IERC20(weth()).balanceOf(address(this));
	}

	function ethSupplyTarget() external view virtual override returns (uint256) {
		(uint128 targetNum, uint128 targetDen) = targetCRatio();
		return ethToExactEthtx(ethtxOutstanding()).mul(targetNum).div(targetDen);
	}

	function ethtxAvailable() public view virtual override returns (uint256) {
		return IERC20(ethtx()).balanceOf(address(this));
	}

	function ethtxOutstanding() public view virtual override returns (uint256) {
		return IERC20(ethtx()).totalSupply().sub(ethtxAvailable());
	}

	function feeLogic() public view virtual override returns (address) {
		return IERC20TxFee(ethtx()).feeLogic();
	}

	function gasOracle() public view virtual override returns (address) {
		return _gasOracle;
	}

	function gasPrice() public view virtual override returns (uint256) {
		return IGasPrice(gasOracle()).gasPrice();
	}

	function gasPriceAtRedemption()
		public
		view
		virtual
		override
		returns (uint256)
	{
		// Apply cap when collateral below target
		uint256 gasPrice_ = gasPrice();
		uint256 maxGasPrice_ = maxGasPrice();
		if (gasPrice_ > maxGasPrice_) {
			gasPrice_ = maxGasPrice_;
		}
		return gasPrice_;
	}

	function geth() public view virtual override returns (uint256) {
		return _geth;
	}

	function maxGasPrice() public view virtual override returns (uint256) {
		uint256 liability = ethtxOutstanding();
		if (liability == 0) {
			return gasPrice();
		}

		(uint128 targetNum, uint128 targetDen) = targetCRatio();

		uint256 numerator = ethSupply().mul(1e18).mul(targetDen);
		uint256 denominator = liability.mul(gasPerETHtx()).mul(targetNum);
		return numerator.div(denominator);
	}

	function targetCRatio()
		public
		view
		virtual
		override
		returns (uint128 numerator, uint128 denominator)
	{
		numerator = _targetCRatioNum;
		denominator = _targetCRatioDen;
	}

	function weth() public view virtual override returns (address) {
		return _weth;
	}

	/* Internal Pure */

	function _ethtxToEth(uint256 gasPrice_, uint256 amountETHtx)
		internal
		pure
		virtual
		returns (uint256)
	{
		return gasPrice_.mul(amountETHtx).mul(gasPerETHtx()) / 1e18;
	}

	function _ethToEthtx(uint256 gasPrice_, uint256 amountETH)
		internal
		pure
		virtual
		returns (uint256)
	{
		require(gasPrice_ != 0, "ETHtxAMM: gasPrice is zero");
		return amountETH.mul(1e18) / gasPrice_.mul(gasPerETHtx());
	}

	/* Internal Mutators */

	function _swapEthForEthtxRaw(
		uint256 amountIn,
		uint256 deadline,
		bool useWETH
	) internal virtual ensure(deadline) priceIsFresh {
		require(amountIn != 0, "ETHtxAMM: cannot swap zero");
		uint256 amountOut = exactEthToEthtx(amountIn);
		_swapEthForEthtx(_msgSender(), amountIn, amountOut, useWETH);
	}

	function _swapEthForExactEthtx(
		uint256 amountInMax,
		uint256 amountOut,
		uint256 deadline,
		bool useWETH
	) internal virtual ensure(deadline) priceIsFresh returns (uint256 amountIn) {
		require(amountInMax != 0, "ETHtxAMM: cannot swap zero");
		// Add 1 to account for rounding (can't get ETHtx for 0 wei)
		amountIn = ethToExactEthtx(amountOut).add(1);
		require(amountIn <= amountInMax, "ETHtxAMM: amountIn exceeds max");
		_swapEthForEthtx(_msgSender(), amountIn, amountOut, useWETH);
	}

	function _swapExactEthForEthtx(
		uint256 amountIn,
		uint256 amountOutMin,
		uint256 deadline,
		bool useWETH
	) internal virtual ensure(deadline) priceIsFresh {
		require(amountIn != 0, "ETHtxAMM: cannot swap zero");
		uint256 amountOut = exactEthToEthtx(amountIn);
		require(amountOut >= amountOutMin, "ETHtxAMM: amountOut below min");
		_swapEthForEthtx(_msgSender(), amountIn, amountOut, useWETH);
	}

	function _swapEthForEthtx(
		address account,
		uint256 amountIn,
		uint256 amountOut,
		bool useWETH
	) internal virtual {
		uint256 availableSupply = IERC20(ethtx()).balanceOf(address(this));
		require(
			availableSupply >= amountOut,
			"ETHtxAMM: not enough ETHtx available"
		);

		if (useWETH) {
			IERC20(weth()).safeTransferFrom(account, address(this), amountIn);
		} else {
			IWETH(weth()).deposit{ value: amountIn }();
		}

		// Bypass fee by setting exemption for AMM contract
		IERC20(ethtx()).safeTransfer(account, amountOut);
	}

	function _swapEthtxForEth(
		address account,
		uint256 amountIn,
		uint256 amountOut,
		bool asWETH
	) internal virtual {
		// Apply fee
		IERC20(ethtx()).safeTransferFrom(account, address(this), amountIn);

		uint256 ethLeft = ethSupply().sub(amountOut);
		if (_geth > ethLeft) {
			_geth = ethLeft;
		}

		if (asWETH) {
			IERC20(weth()).safeTransfer(account, amountOut);
		} else {
			IWETH(weth()).withdraw(amountOut);
			payable(account).sendValue(amountOut);
		}
	}
}

