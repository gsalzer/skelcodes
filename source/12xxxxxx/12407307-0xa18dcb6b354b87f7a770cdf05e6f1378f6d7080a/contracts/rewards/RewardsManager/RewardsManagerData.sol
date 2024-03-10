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

import "@openzeppelin/contracts/utils/EnumerableSet.sol";

abstract contract RewardsManagerData {
	struct Shares {
		uint128 active;
		uint128 total;
	}

	address internal _rewardsToken;
	address internal _defaultRecipient;
	uint256 internal _totalRewardsRedeemed;
	EnumerableSet.AddressSet internal _recipients;
	mapping(address => Shares) internal _shares;

	uint256[45] private __gap;
}

