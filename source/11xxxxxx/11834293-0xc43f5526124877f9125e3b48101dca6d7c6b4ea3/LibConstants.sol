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

contract LibConstants {
    // Durations for time locked mechanisms (in seconds).
    // Note that it is known that miners can manipulate block timestamps
    // up to a deviation of a few seconds.
    // This mechanism should not be used for fine grained timing.

    // The time required to cancel a deposit, in the case the operator does not move the funds
    // to the off-chain storage.
    uint256 public constant DEPOSIT_CANCEL_DELAY = 7 days;

    // The time required to freeze the exchange, in the case the operator does not execute a
    // requested full withdrawal.
    uint256 public constant FREEZE_GRACE_PERIOD = 14 days;

    // The time after which the exchange may be unfrozen after it froze. This should be enough time
    // for users to perform escape hatches to get back their funds.
    uint256 public constant UNFREEZE_DELAY = 365 days;

    // Maximal number of verifiers which may co-exist.
    uint256 public constant MAX_VERIFIER_COUNT = uint256(64);

    // The time required to remove a verifier in case of a verifier upgrade.
    uint256 public constant VERIFIER_REMOVAL_DELAY = FREEZE_GRACE_PERIOD + (21 days);

    address constant ZERO_ADDRESS = address(0x0);

    uint256 constant K_MODULUS =
    0x800000000000011000000000000000000000000000000000000000000000001;

    uint256 constant K_BETA =
    0x6f21413efbe40de150e596d72f7a8c5609ad26c15c915c1f4cdfcb99cee9e89;

    uint256 internal constant MASK_250 =
    0x03FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    uint256 internal constant MASK_240 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    uint256 public constant MAX_FORCED_ACTIONS_REQS_PER_BLOCK = 10;

    // ======================================================
    //            StarkEx specific constants
    // ======================================================
    uint256 constant STARKEX_MAX_VAULT_ID = 2**31 - 1;
    uint256 constant STARKEX_MAX_QUANTUM = 2**128 - 1;
    uint256 constant STARKEX_EXPIRATION_TIMESTAMP_BITS = 22;
    uint256 internal constant STARKEX_MINTABLE_ASSET_ID_FLAG = 1<<250;

    // ======================================================
    //            StarkEx specific constants
    // ======================================================
    uint256 constant PERPETUAL_POSITION_ID_UPPER_BOUND = 2**64;
    uint256 constant PERPETUAL_AMOUNT_UPPER_BOUND = 2**64;
    uint256 constant PERPETUAL_TIMESTAMP_BITS = 32;
    uint256 constant PERPETUAL_ASSET_ID_UPPER_BOUND = 2**120;
    uint256 constant PERPETUAL_SYSTEM_TIME_LAG_BOUND = 14 days;
    uint256 constant PERPETUAL_SYSTEM_TIME_ADVANCE_BOUND = 4 hours;
    uint256 constant PERPETUAL_CONFIGURATION_DELAY = 0;
}

