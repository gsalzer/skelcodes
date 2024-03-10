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
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./ETHmxMinterData.sol";
import "../../tokens/interfaces/IETHmx.sol";
import "../interfaces/IETHmxMinter.sol";
import "../../tokens/interfaces/IETHtx.sol";
import "../interfaces/IETHtxAMM.sol";
import "../../tokens/interfaces/IWETH.sol";
import "../../access/OwnableUpgradeable.sol";
import "../../libraries/UintLog.sol";

/* solhint-disable not-rely-on-time */

interface IPool {
	function addLiquidity(
		address tokenA,
		address tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	)
		external
		returns (
			uint256 amountA,
			uint256 amountB,
			uint256 liquidity
		);
}

contract ETHmxMinter is
	Initializable,
	ContextUpgradeable,
	OwnableUpgradeable,
	PausableUpgradeable,
	ETHmxMinterData,
	IETHmxMinter
{
	using EnumerableSet for EnumerableSet.AddressSet;
	using SafeERC20 for IERC20;
	using SafeMath for uint256;
	using SafeMath for uint32;
	using UintLog for uint256;

	struct ETHmxMinterArgs {
		address ethmx;
		address ethtx;
		address ethtxAMM;
		address weth;
		ETHmxMintParams ethmxMintParams;
		ETHtxMintParams ethtxMintParams;
		uint128 lpShareNumerator;
		uint128 lpShareDenominator;
		address[] lps;
		address lpRecipient;
	}

	uint256 internal constant _GAS_PER_ETHTX = 21000; // per 1e18
	uint256 internal constant _GENESIS_START = 1620655200; // 05/10/2021 1400 UTC
	uint256 internal constant _GENESIS_END = 1621260000; // 05/17/2021 1400 UTC
	uint256 internal constant _GENESIS_AMOUNT = 3e21; // 3k ETH

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

	function postInit(ETHmxMinterArgs memory _args) external virtual onlyOwner {
		address sender = _msgSender();

		_ethmx = _args.ethmx;
		emit EthmxSet(sender, _args.ethmx);

		_ethtx = _args.ethtx;
		emit EthtxSet(sender, _args.ethtx);

		_ethtxAMM = _args.ethtxAMM;
		emit EthtxAMMSet(sender, _args.ethtxAMM);

		_weth = _args.weth;
		emit WethSet(sender, _args.weth);

		_ethmxMintParams = _args.ethmxMintParams;
		emit EthmxMintParamsSet(sender, _args.ethmxMintParams);

		_inGenesis = block.timestamp <= _GENESIS_END;
		_minMintPrice = _args.ethtxMintParams.minMintPrice;
		_mu = _args.ethtxMintParams.mu;
		_lambda = _args.ethtxMintParams.lambda;
		emit EthtxMintParamsSet(sender, _args.ethtxMintParams);

		_lpShareNum = _args.lpShareNumerator;
		_lpShareDen = _args.lpShareDenominator;
		emit LpShareSet(sender, _args.lpShareNumerator, _args.lpShareDenominator);

		for (uint256 i = 0; i < _lps.length(); i++) {
			address lp = _lps.at(i);
			_lps.remove(lp);
			emit LpRemoved(sender, lp);
		}
		for (uint256 i = 0; i < _args.lps.length; i++) {
			address lp = _args.lps[i];
			_lps.add(lp);
			emit LpAdded(sender, lp);
		}

		_lpRecipient = _args.lpRecipient;
		emit LpRecipientSet(sender, _args.lpRecipient);
	}

	function addLp(address pool) external virtual override onlyOwner {
		bool added = _lps.add(pool);
		require(added, "ETHmxMinter: liquidity pool already added");
		emit LpAdded(_msgSender(), pool);
	}

	function mint() external payable virtual override whenNotPaused {
		require(block.timestamp >= _GENESIS_START, "ETHmxMinter: before genesis");
		uint256 amountIn = msg.value;
		require(amountIn != 0, "ETHmxMinter: cannot mint with zero amount");

		// Convert to WETH
		address weth_ = weth();
		IWETH(weth_).deposit{ value: amountIn }();

		// Check if we're in genesis
		bool exitingGenesis;
		uint256 ethToMintEthtx = amountIn;
		if (_inGenesis) {
			uint256 totalGiven_ = _totalGiven.add(amountIn);
			if (block.timestamp >= _GENESIS_END || totalGiven_ >= _GENESIS_AMOUNT) {
				// Exiting genesis
				ethToMintEthtx = totalGiven_;
				exitingGenesis = true;
			} else {
				ethToMintEthtx = 0;
			}
		}

		// Mint ETHtx and send ETHtx-WETH pair.
		_mintEthtx(ethToMintEthtx);

		// Mint ETHmx to sender.
		uint256 amountOut = ethmxFromEth(amountIn);
		_mint(_msgSender(), amountOut);
		_totalGiven += amountIn;
		// WARN this could cause re-entrancy if we ever called an unkown address
		if (exitingGenesis) {
			_inGenesis = false;
		}
	}

	function mintWithETHtx(uint256 amount)
		external
		virtual
		override
		whenNotPaused
	{
		require(amount != 0, "ETHmxMinter: cannot mint with zero amount");

		IETHtxAMM ammHandle = IETHtxAMM(ethtxAMM());
		uint256 amountETHIn = ammHandle.ethToExactEthtx(amount);
		require(
			ammHandle.ethNeeded() >= amountETHIn,
			"ETHmxMinter: ETHtx value burnt exceeds ETH needed"
		);

		address account = _msgSender();
		IETHtx(ethtx()).burn(account, amount);

		_mint(account, amountETHIn);
	}

	function mintWithWETH(uint256 amount)
		external
		virtual
		override
		whenNotPaused
	{
		require(block.timestamp >= _GENESIS_START, "ETHmxMinter: before genesis");
		require(amount != 0, "ETHmxMinter: cannot mint with zero amount");
		address account = _msgSender();

		// Need ownership for router
		IERC20(weth()).safeTransferFrom(account, address(this), amount);

		// Check if we're in genesis
		bool exitingGenesis;
		uint256 ethToMintEthtx = amount;
		if (_inGenesis) {
			uint256 totalGiven_ = _totalGiven.add(amount);
			if (block.timestamp >= _GENESIS_END || totalGiven_ >= _GENESIS_AMOUNT) {
				// Exiting genesis
				ethToMintEthtx = totalGiven_;
				exitingGenesis = true;
			} else {
				ethToMintEthtx = 0;
			}
		}

		// Mint ETHtx and send ETHtx-WETH pair.
		_mintEthtx(ethToMintEthtx);

		uint256 amountOut = ethmxFromEth(amount);
		_mint(account, amountOut);
		_totalGiven += amount;
		// WARN this could cause re-entrancy if we ever called an unkown address
		if (exitingGenesis) {
			_inGenesis = false;
		}
	}

	function pause() external virtual override onlyOwner {
		_pause();
	}

	function recoverERC20(
		address token,
		address to,
		uint256 amount
	) external virtual override onlyOwner {
		require(token != _weth, "ETHmxMinter: cannot recover WETH");
		IERC20(token).safeTransfer(to, amount);
		emit Recovered(_msgSender(), token, to, amount);
	}

	function removeLp(address pool) external virtual override onlyOwner {
		bool removed = _lps.remove(pool);
		require(removed, "ETHmxMinter: liquidity pool not present");
		emit LpRemoved(_msgSender(), pool);
	}

	function setEthmx(address addr) public virtual override onlyOwner {
		_ethmx = addr;
		emit EthmxSet(_msgSender(), addr);
	}

	function setEthmxMintParams(ETHmxMintParams memory mp)
		public
		virtual
		override
		onlyOwner
	{
		_ethmxMintParams = mp;
		emit EthmxMintParamsSet(_msgSender(), mp);
	}

	function setEthtxMintParams(ETHtxMintParams memory mp)
		public
		virtual
		override
		onlyOwner
	{
		_minMintPrice = mp.minMintPrice;
		_mu = mp.mu;
		_lambda = mp.lambda;
		emit EthtxMintParamsSet(_msgSender(), mp);
	}

	function setEthtx(address addr) public virtual override onlyOwner {
		_ethtx = addr;
		emit EthtxSet(_msgSender(), addr);
	}

	function setEthtxAMM(address addr) public virtual override onlyOwner {
		_ethtxAMM = addr;
		emit EthtxAMMSet(_msgSender(), addr);
	}

	function setLpRecipient(address account)
		external
		virtual
		override
		onlyOwner
	{
		_lpRecipient = account;
		emit LpRecipientSet(_msgSender(), account);
	}

	function setLpShare(uint128 numerator, uint128 denominator)
		external
		virtual
		override
		onlyOwner
	{
		// Also guarantees that the denominator cannot be zero.
		require(denominator > numerator, "ETHmxMinter: cannot set lpShare >= 1");
		_lpShareNum = numerator;
		_lpShareDen = denominator;
		emit LpShareSet(_msgSender(), numerator, denominator);
	}

	function setWeth(address addr) public virtual override onlyOwner {
		_weth = addr;
		emit WethSet(_msgSender(), addr);
	}

	function unpause() external virtual override onlyOwner {
		_unpause();
	}

	/* Public Views */

	function ethmx() public view virtual override returns (address) {
		return _ethmx;
	}

	function ethmxMintParams()
		public
		view
		virtual
		override
		returns (ETHmxMintParams memory)
	{
		return _ethmxMintParams;
	}

	function ethmxFromEth(uint256 amountETHIn)
		public
		view
		virtual
		override
		returns (uint256)
	{
		if (amountETHIn == 0) {
			return 0;
		}

		ETHmxMintParams memory mp = _ethmxMintParams;
		uint256 amountOut = _ethmxCurve(amountETHIn, mp);

		if (_inGenesis) {
			uint256 totalGiven_ = _totalGiven;
			uint256 totalEnd = totalGiven_.add(amountETHIn);

			if (totalEnd > _GENESIS_AMOUNT) {
				// Exiting genesis
				uint256 amtUnder = _GENESIS_AMOUNT - totalGiven_;
				amountOut -= amtUnder.mul(amountOut).div(amountETHIn);
				uint256 added =
					amtUnder.mul(2).mul(mp.zetaFloorNum).div(mp.zetaFloorDen);
				return amountOut.add(added);
			}

			return amountOut.mul(2);
		}

		return amountOut;
	}

	function ethmxFromEthtx(uint256 amountETHtxIn)
		public
		view
		virtual
		override
		returns (uint256)
	{
		return IETHtxAMM(ethtxAMM()).ethToExactEthtx(amountETHtxIn);
	}

	function ethtx() public view virtual override returns (address) {
		return _ethtx;
	}

	function ethtxMintParams()
		public
		view
		virtual
		override
		returns (ETHtxMintParams memory)
	{
		return ETHtxMintParams(_minMintPrice, _mu, _lambda);
	}

	function ethtxAMM() public view virtual override returns (address) {
		return _ethtxAMM;
	}

	function ethtxFromEth(uint256 amountETHIn)
		public
		view
		virtual
		override
		returns (uint256)
	{
		if (amountETHIn == 0) {
			return 0;
		}

		IETHtxAMM ammHandle = IETHtxAMM(_ethtxAMM);
		(uint256 collat, uint256 liability) = ammHandle.cRatio();
		uint256 gasPrice = ammHandle.gasPrice();

		uint256 basePrice;
		uint256 lambda_;
		{
			uint256 minMintPrice_ = _minMintPrice;
			uint256 mu_ = _mu;
			lambda_ = _lambda;

			basePrice = mu_.mul(gasPrice).add(minMintPrice_);
		}

		if (liability == 0) {
			// If exiting genesis, flat 2x on minting price up to threshold
			if (_inGenesis) {
				uint256 totalGiven_ = _totalGiven;
				uint256 totalEnd = totalGiven_.add(amountETHIn);

				if (totalEnd > _GENESIS_AMOUNT) {
					uint256 amtOver = totalEnd - _GENESIS_AMOUNT;
					uint256 amtOut =
						_ethToEthtx(basePrice.mul(2), amountETHIn - amtOver);
					return amtOut.add(_ethToEthtx(basePrice, amtOver));
				}
				return _ethToEthtx(basePrice.mul(2), amountETHIn);
			}

			return _ethToEthtx(basePrice, amountETHIn);
		}

		uint256 ethTarget;
		{
			(uint256 cTargetNum, uint256 cTargetDen) = ammHandle.targetCRatio();
			ethTarget = liability.mul(cTargetNum).div(cTargetDen);
		}

		if (collat < ethTarget) {
			uint256 ethEnd = collat.add(amountETHIn);
			if (ethEnd <= ethTarget) {
				return 0;
			}
			amountETHIn = ethEnd - ethTarget;
			collat = ethTarget;
		}

		uint256 firstTerm = basePrice.mul(amountETHIn);

		uint256 collatDiff = collat - liability;
		uint256 coeffA = lambda_.mul(liability).mul(gasPrice);

		uint256 secondTerm =
			basePrice.mul(collatDiff).add(coeffA).mul(1e18).ln().mul(coeffA);
		secondTerm /= 1e18;

		uint256 thirdTerm = basePrice.mul(collatDiff.add(amountETHIn));
		// avoids stack too deep error
		thirdTerm = thirdTerm.add(coeffA).mul(1e18).ln().mul(coeffA) / 1e18;

		uint256 numerator = firstTerm.add(secondTerm).sub(thirdTerm).mul(1e18);
		uint256 denominator = _GAS_PER_ETHTX.mul(basePrice).mul(basePrice);
		return numerator.div(denominator);
	}

	function inGenesis() external view virtual override returns (bool) {
		return _inGenesis;
	}

	function numLiquidityPools()
		external
		view
		virtual
		override
		returns (uint256)
	{
		return _lps.length();
	}

	function liquidityPoolsAt(uint256 index)
		external
		view
		virtual
		override
		returns (address)
	{
		return _lps.at(index);
	}

	function lpRecipient() public view virtual override returns (address) {
		return _lpRecipient;
	}

	function lpShare()
		public
		view
		virtual
		override
		returns (uint128 numerator, uint128 denominator)
	{
		numerator = _lpShareNum;
		denominator = _lpShareDen;
	}

	function totalGiven() public view virtual override returns (uint256) {
		return _totalGiven;
	}

	function weth() public view virtual override returns (address) {
		return _weth;
	}

	/* Internal Views */

	function _ethmxCurve(uint256 amountETHIn, ETHmxMintParams memory mp)
		internal
		view
		virtual
		returns (uint256)
	{
		uint256 cRatioNum;
		uint256 cRatioDen;
		uint256 cTargetNum;
		uint256 cTargetDen;
		{
			IETHtxAMM ammHandle = IETHtxAMM(_ethtxAMM);
			(cRatioNum, cRatioDen) = ammHandle.cRatio();

			if (cRatioDen == 0) {
				// cRatio > cCap
				return amountETHIn.mul(mp.zetaFloorNum).div(mp.zetaFloorDen);
			}

			(cTargetNum, cTargetDen) = ammHandle.targetCRatio();
		}

		uint256 ethEnd = cRatioNum.add(amountETHIn);
		uint256 ethTarget = cRatioDen.mul(cTargetNum).div(cTargetDen);
		uint256 ethCap = cRatioDen.mul(mp.cCapNum).div(mp.cCapDen);
		if (cRatioNum >= ethCap) {
			// cRatio >= cCap
			return amountETHIn.mul(mp.zetaFloorNum).div(mp.zetaFloorDen);
		}

		if (cRatioNum < ethTarget) {
			// cRatio < cTarget
			if (ethEnd > ethCap) {
				// Add definite integral
				uint256 curveAmt =
					_ethmxDefiniteIntegral(
						ethCap - ethTarget,
						mp,
						cTargetNum,
						cTargetDen,
						ethTarget,
						cRatioDen
					);

				// Add amount past cap
				uint256 pastCapAmt =
					(ethEnd - ethCap).mul(mp.zetaFloorNum).div(mp.zetaFloorDen);

				// add initial amount
				uint256 flatAmt =
					(ethTarget - cRatioNum).mul(mp.zetaCeilNum).div(mp.zetaCeilDen);

				return flatAmt.add(curveAmt).add(pastCapAmt);
			} else if (ethEnd > ethTarget) {
				// Add definite integral for partial amount
				uint256 ethOver = ethEnd - ethTarget;
				uint256 curveAmt =
					_ethmxDefiniteIntegral(
						ethOver,
						mp,
						cTargetNum,
						cTargetDen,
						ethTarget,
						cRatioDen
					);

				uint256 ethBeforeCurve = amountETHIn - ethOver;
				uint256 flatAmt =
					ethBeforeCurve.mul(mp.zetaCeilNum).div(mp.zetaCeilDen);
				return flatAmt.add(curveAmt);
			}

			return amountETHIn.mul(mp.zetaCeilNum).div(mp.zetaCeilDen);
		}

		// cTarget < cRatio < cCap
		if (ethEnd > ethCap) {
			uint256 ethOver = ethEnd - ethCap;
			uint256 curveAmt =
				_ethmxDefiniteIntegral(
					amountETHIn - ethOver,
					mp,
					cTargetNum,
					cTargetDen,
					cRatioNum,
					cRatioDen
				);

			uint256 flatAmt = ethOver.mul(mp.zetaFloorNum).div(mp.zetaFloorDen);

			return curveAmt.add(flatAmt);
		}

		return
			_ethmxDefiniteIntegral(
				amountETHIn,
				mp,
				cTargetNum,
				cTargetDen,
				cRatioNum,
				cRatioDen
			);
	}

	function _ethmxDefiniteIntegral(
		uint256 amountETHIn,
		ETHmxMintParams memory mp,
		uint256 cTargetNum,
		uint256 cTargetDen,
		uint256 initCollateral,
		uint256 liability
	) internal pure virtual returns (uint256) {
		uint256 fctMulNum = mp.zetaFloorNum.mul(mp.zetaCeilDen).mul(cTargetDen);
		uint256 fctMulDen = mp.zetaFloorDen.mul(mp.zetaCeilNum).mul(cTargetNum);

		// prettier-ignore
		uint256 first =
			amountETHIn
			.mul(fctMulNum.mul(mp.cCapNum))
			.div(fctMulDen.mul(mp.cCapDen));

		uint256 second = amountETHIn.mul(mp.zetaFloorNum).div(mp.zetaFloorDen);

		uint256 tNum = fctMulNum.mul(amountETHIn);
		uint256 tDen = fctMulDen.mul(2).mul(liability);
		uint256 third = initCollateral.mul(2).add(amountETHIn);
		// avoids stack too deep error
		third = third.mul(tNum).div(tDen);

		return first.add(second).sub(third);
	}

	function _ethToEthtx(uint256 gasPrice, uint256 amountETH)
		internal
		pure
		virtual
		returns (uint256)
	{
		require(gasPrice != 0, "ETHmxMinter: gasPrice is zero");
		return amountETH.mul(1e18) / gasPrice.mul(_GAS_PER_ETHTX);
	}

	/* Internal Mutators */

	function _mint(address account, uint256 amount) internal virtual {
		IETHmx(ethmx()).mintTo(account, amount);
	}

	function _mintEthtx(uint256 amountEthIn) internal virtual {
		// Mint ETHtx.
		uint256 ethtxToMint = ethtxFromEth(amountEthIn);

		if (ethtxToMint == 0) {
			return;
		}

		address ethtx_ = ethtx();
		IETHtx(ethtx_).mint(address(this), ethtxToMint);

		// Lock portion into liquidity in designated pools
		(uint256 ethtxSentToLp, uint256 ethSentToLp) = _sendToLps(ethtxToMint);

		// Send the rest to the AMM.
		address ethtxAmm_ = ethtxAMM();
		IERC20(weth()).safeTransfer(ethtxAmm_, amountEthIn.sub(ethSentToLp));
		IERC20(ethtx_).safeTransfer(ethtxAmm_, ethtxToMint.sub(ethtxSentToLp));
	}

	function _sendToLps(uint256 ethtxTotal)
		internal
		virtual
		returns (uint256 totalEthtxSent, uint256 totalEthSent)
	{
		uint256 numLps = _lps.length();
		if (numLps == 0) {
			return (0, 0);
		}

		(uint256 lpShareNum, uint256 lpShareDen) = lpShare();
		if (lpShareNum == 0) {
			return (0, 0);
		}

		uint256 ethtxToLp = ethtxTotal.mul(lpShareNum).div(lpShareDen).div(numLps);
		uint256 ethToLp = IETHtxAMM(ethtxAMM()).ethToExactEthtx(ethtxToLp);
		address ethtx_ = ethtx();
		address weth_ = weth();
		address to = lpRecipient();

		for (uint256 i = 0; i < numLps; i++) {
			address pool = _lps.at(i);

			IERC20(ethtx_).safeIncreaseAllowance(pool, ethtxToLp);
			IERC20(weth_).safeIncreaseAllowance(pool, ethToLp);

			(uint256 ethtxSent, uint256 ethSent, ) =
				IPool(pool).addLiquidity(
					ethtx_,
					weth_,
					ethtxToLp,
					ethToLp,
					0,
					0,
					to,
					// solhint-disable-next-line not-rely-on-time
					block.timestamp
				);

			totalEthtxSent = totalEthtxSent.add(ethtxSent);
			totalEthSent = totalEthSent.add(ethSent);
		}
	}
}

