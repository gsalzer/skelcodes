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

interface IETHmxMinter {
	/* Types */

	struct ETHmxMintParams {
		// Uses a single 32 byte slot and avoids stack too deep errors
		uint32 cCapNum;
		uint32 cCapDen;
		uint32 zetaFloorNum;
		uint32 zetaFloorDen;
		uint32 zetaCeilNum;
		uint32 zetaCeilDen;
	}

	struct ETHtxMintParams {
		uint128 minMintPrice;
		uint64 mu;
		uint64 lambda;
	}

	/* Views */

	function ethmx() external view returns (address);

	function ethmxMintParams() external view returns (ETHmxMintParams memory);

	function ethmxFromEth(uint256 amountETHIn) external view returns (uint256);

	function ethmxFromEthtx(uint256 amountETHtxIn)
		external
		view
		returns (uint256);

	function ethtx() external view returns (address);

	function ethtxMintParams() external view returns (ETHtxMintParams memory);

	function ethtxAMM() external view returns (address);

	function ethtxFromEth(uint256 amountETHIn) external view returns (uint256);

	function inGenesis() external view returns (bool);

	function numLiquidityPools() external view returns (uint256);

	function liquidityPoolsAt(uint256 index) external view returns (address);

	function lpRecipient() external view returns (address);

	function lpShare()
		external
		view
		returns (uint128 numerator, uint128 denominator);

	function totalGiven() external view returns (uint256);

	function weth() external view returns (address);

	/* Mutators */

	function addLp(address pool) external;

	function mint() external payable;

	function mintWithETHtx(uint256 amountIn) external;

	function mintWithWETH(uint256 amountIn) external;

	function pause() external;

	function recoverERC20(
		address token,
		address to,
		uint256 amount
	) external;

	function removeLp(address pool) external;

	function setEthmx(address addr) external;

	function setEthmxMintParams(ETHmxMintParams memory mp) external;

	function setEthtxMintParams(ETHtxMintParams memory mp) external;

	function setEthtx(address addr) external;

	function setEthtxAMM(address addr) external;

	function setLpRecipient(address account) external;

	function setLpShare(uint128 numerator, uint128 denominator) external;

	function setWeth(address addr) external;

	function unpause() external;

	/* Events */

	event EthmxSet(address indexed author, address indexed addr);
	event EthmxMintParamsSet(address indexed author, ETHmxMintParams mp);
	event EthtxMintParamsSet(address indexed author, ETHtxMintParams mp);
	event EthtxSet(address indexed author, address indexed addr);
	event EthtxAMMSet(address indexed author, address indexed addr);
	event LpAdded(address indexed author, address indexed account);
	event LpRecipientSet(address indexed author, address indexed account);
	event LpRemoved(address indexed author, address indexed account);
	event LpShareSet(
		address indexed author,
		uint128 numerator,
		uint128 denominator
	);
	event Recovered(
		address indexed author,
		address indexed token,
		address indexed to,
		uint256 amount
	);
	event WethSet(address indexed author, address indexed addr);
}

