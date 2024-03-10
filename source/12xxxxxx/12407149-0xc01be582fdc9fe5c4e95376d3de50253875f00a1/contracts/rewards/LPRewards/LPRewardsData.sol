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

import "../../libraries/EnumerableMap.sol";

abstract contract LPRewardsData {
	/* Structs */

	struct TokenData {
		uint256 arpt;
		uint256 lastRewardsAccrued;
		uint256 rewards;
		uint256 rewardsRedeemed;
		uint256 totalStaked;
		address valueImpl;
	}

	struct UserTokenRewards {
		uint256 pending;
		uint256 arptLast;
	}

	struct UserData {
		EnumerableSet.AddressSet tokensWithRewards;
		mapping(address => UserTokenRewards) rewardsFor;
		EnumerableMap.AddressToUintMap staked;
	}

	/* State */

	address internal _rewardsToken;
	uint256 internal _lastTotalRewardsAccrued;
	uint256 internal _totalRewardsRedeemed;
	uint256 internal _unredeemableRewards;
	EnumerableSet.AddressSet internal _tokens;
	mapping(address => TokenData) internal _tokenData;
	mapping(address => UserData) internal _users;

	uint256[43] private __gap;
}

