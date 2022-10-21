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

import "StarkExStorage.sol";
import "StarkExConstants.sol";
import "MVaultLocks.sol";
import "MGovernance.sol";

/*
  Onchain vaults' lock functionality.
*/
abstract contract VaultLocks is StarkExStorage, StarkExConstants, MGovernance, MVaultLocks {
    event LogDefaultVaultWithdrawalLockSet(uint256 newDefaultLockTime);
    event LogVaultWithdrawalLockSet(
        address ethKey,
        uint256 assetId,
        uint256 vaultId,
        uint256 timeRelease
    );

    function initialize(uint256 defaultLockTime) internal {
        setDefaultVaultWithdrawalLock(defaultLockTime);
    }

    // NOLINTNEXTLINE external-function.
    function setDefaultVaultWithdrawalLock(uint256 newDefaultTime) public onlyGovernance {
        require(newDefaultTime <= STARKEX_MAX_DEFAULT_VAULT_LOCK, "DEFAULT_LOCK_TIME_TOO_LONG");
        defaultVaultWithdrawalLock = newDefaultTime;
        emit LogDefaultVaultWithdrawalLockSet(newDefaultTime);
    }

    function getVaultWithdrawalLock(
        address ethKey,
        uint256 assetId,
        uint256 vaultId
    ) public view returns (uint256) {
        return vaultsWithdrawalLocks[ethKey][assetId][vaultId];
    }

    function lockVault(
        uint256 assetId,
        uint256 vaultId,
        uint256 lockTime
    ) public {
        uint256 currentLockRelease = getVaultWithdrawalLock(msg.sender, assetId, vaultId);
        uint256 timeRelease = block.timestamp + lockTime;
        require(timeRelease >= currentLockRelease, "INVALID_LOCK_TIME");

        vaultsWithdrawalLocks[msg.sender][assetId][vaultId] = timeRelease;
        emit LogVaultWithdrawalLockSet(msg.sender, assetId, vaultId, timeRelease);
    }

    function applyDefaultLock(uint256 assetId, uint256 vaultId) internal override {
        uint256 currentLockRelease = getVaultWithdrawalLock(msg.sender, assetId, vaultId);
        if (currentLockRelease < block.timestamp + defaultVaultWithdrawalLock) {
            lockVault(assetId, vaultId, defaultVaultWithdrawalLock);
        }
    }

    function isVaultLocked( // NOLINT external-function.
        address ethKey,
        uint256 assetId,
        uint256 vaultId
    ) public view override returns (bool) {
        uint256 timeRelease = getVaultWithdrawalLock(ethKey, assetId, vaultId);
        return (block.timestamp < timeRelease);
    }
}

