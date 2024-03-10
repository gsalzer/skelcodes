/*
  Copyright 2019,2020 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.11;

import "MainStorage.sol";
import "MKeyGetters.sol";

/*
  Implements MKeyGetters.
*/
contract KeyGetters is MainStorage, MKeyGetters {
    function getEthKey(uint256 starkKey) public view
        override returns (address ethKey) {
        // Fetch the user's Ethereum key.
        ethKey = ethKeys[starkKey];
        require(ethKey != address(0x0), "USER_UNREGISTERED");
    }

    function isMsgSenderStarkKeyOwner(uint256 starkKey) internal view
        override returns (bool) {
        return msg.sender == getEthKey(starkKey);
    }

    modifier isSenderStarkKey(uint256 starkKey) override {
        // Require the calling user to own the stark key.
        require(isMsgSenderStarkKeyOwner(starkKey), "MISMATCHING_STARK_ETH_KEYS");
        _;
    }
}

