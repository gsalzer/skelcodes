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

interface IGasPrice {
	/* Views */

	function gasPrice() external view returns (uint256);

	function hasPriceExpired() external view returns (bool);

	function updateThreshold() external view returns (uint256);

	function updatedAt() external view returns (uint256);

	/* Mutators */

	function setGasPrice(uint256 _gasPrice) external;

	function setUpdateThreshold(uint256 _updateThreshold) external;

	/* Events */

	event GasPriceUpdate(address indexed author, uint256 newValue);
	event UpdateThresholdSet(address indexed author, uint256 value);
}

