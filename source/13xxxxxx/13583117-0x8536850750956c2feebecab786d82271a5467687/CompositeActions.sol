/*
  Copyright 2019-2021 StarkWare Industries Ltd.

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

import "MDeposits.sol";

abstract contract CompositeActions is MDeposits {
    function registerAndDepositERC20(
        address ethKey,
        uint256 starkKey,
        bytes calldata signature,
        uint256 assetType,
        uint256 vaultId,
        uint256 quantizedAmount
    ) external {
        depositERC20(starkKey, assetType, vaultId, quantizedAmount);
    }

    // NOLINTNEXTLINE: locked-ether.
    function registerAndDepositEth(
        address ethKey,
        uint256 starkKey,
        bytes calldata signature,
        uint256 assetType,
        uint256 vaultId
    ) external payable {
        depositEth(starkKey, assetType, vaultId);
    }
}

