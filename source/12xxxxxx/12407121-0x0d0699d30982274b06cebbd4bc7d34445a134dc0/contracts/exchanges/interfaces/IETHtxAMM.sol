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

interface IETHtxAMM {
	/* Views */

	function cRatio()
		external
		view
		returns (uint256 numerator, uint256 denominator);

	function cRatioBelowTarget() external view returns (bool);

	function ethNeeded() external view returns (uint256);

	function ethtx() external view returns (address);

	function exactEthToEthtx(uint256 amountEthIn)
		external
		view
		returns (uint256);

	function ethToExactEthtx(uint256 amountEthtxOut)
		external
		view
		returns (uint256);

	function exactEthtxToEth(uint256 amountEthtxIn)
		external
		view
		returns (uint256);

	function ethtxToExactEth(uint256 amountEthOut)
		external
		view
		returns (uint256);

	function ethSupply() external view returns (uint256);

	function ethSupplyTarget() external view returns (uint256);

	function ethtxAvailable() external view returns (uint256);

	function ethtxOutstanding() external view returns (uint256);

	function feeLogic() external view returns (address);

	function gasOracle() external view returns (address);

	function gasPerETHtx() external pure returns (uint256);

	function gasPrice() external view returns (uint256);

	function gasPriceAtRedemption() external view returns (uint256);

	function maxGasPrice() external view returns (uint256);

	function targetCRatio()
		external
		view
		returns (uint128 numerator, uint128 denominator);

	function weth() external view returns (address);

	/* Mutators */

	function swapEthForEthtx(uint256 deadline) external payable;

	function swapWethForEthtx(uint256 amountIn, uint256 deadline) external;

	function swapEthForExactEthtx(uint256 amountOut, uint256 deadline)
		external
		payable;

	function swapWethForExactEthtx(
		uint256 amountInMax,
		uint256 amountOut,
		uint256 deadline
	) external;

	function swapExactEthForEthtx(uint256 amountOutMin, uint256 deadline)
		external
		payable;

	function swapExactWethForEthtx(
		uint256 amountIn,
		uint256 amountOutMin,
		uint256 deadline
	) external;

	function swapEthtxForEth(
		uint256 amountIn,
		uint256 deadline,
		bool asWETH
	) external;

	function swapEthtxForExactEth(
		uint256 amountInMax,
		uint256 amountOut,
		uint256 deadline,
		bool asWETH
	) external;

	function swapExactEthtxForEth(
		uint256 amountIn,
		uint256 amountOutMin,
		uint256 deadline,
		bool asWETH
	) external;

	function pause() external;

	function recoverUnsupportedERC20(
		address token,
		address to,
		uint256 amount
	) external;

	function setEthtx(address account) external;

	function setGasOracle(address account) external;

	function setTargetCRatio(uint128 numerator, uint128 denominator) external;

	function setWETH(address account) external;

	function unpause() external;

	/* Events */

	event ETHtxSet(address indexed author, address indexed account);
	event GasOracleSet(address indexed author, address indexed account);
	event RecoveredUnsupported(
		address indexed author,
		address indexed token,
		address indexed to,
		uint256 amount
	);
	event TargetCRatioSet(
		address indexed author,
		uint128 numerator,
		uint128 denominator
	);
	event WETHSet(address indexed author, address indexed account);
}

