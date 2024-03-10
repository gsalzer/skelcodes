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

contract PublicInputOffsets {
    // The following constants are offsets of data expected in the public input.
    uint256 internal constant PUB_IN_INITIAL_VAULT_ROOT_OFFSET = 0;
    uint256 internal constant PUB_IN_FINAL_VAULT_ROOT_OFFSET = 1;
    uint256 internal constant PUB_IN_INITIAL_ORDER_ROOT_OFFSET = 2;
    uint256 internal constant PUB_IN_FINAL_ORDER_ROOT_OFFSET = 3;
    uint256 internal constant PUB_IN_GLOBAL_EXPIRATION_TIMESTAMP_OFFSET = 4;
    uint256 internal constant PUB_IN_VAULT_TREE_HEIGHT_OFFSET = 5;
    uint256 internal constant PUB_IN_ORDER_TREE_HEIGHT_OFFSET = 6;
    uint256 internal constant PUB_IN_ONCHAIN_DATA_VERSION = 7;
    uint256 internal constant PUB_IN_N_MODIFICATIONS_OFFSET = 8;
    uint256 internal constant PUB_IN_N_CONDITIONAL_TRANSFERS_OFFSET = 9;
    uint256 internal constant PUB_IN_N_ONCHAIN_VAULT_UPDATES_OFFSET = 10;
    uint256 internal constant PUB_IN_N_ONCHAIN_ORDERS_OFFSET = 11;
    uint256 internal constant PUB_IN_TRANSACTIONS_DATA_OFFSET = 12;

    uint256 internal constant PUB_IN_N_WORDS_PER_MODIFICATION = 3;
    uint256 internal constant PUB_IN_N_WORDS_PER_CONDITIONAL_TRANSFER = 1;
    uint256 internal constant PUB_IN_N_WORDS_PER_ONCHAIN_VAULT_UPDATE = 3;
    uint256 internal constant PUB_IN_N_MIN_WORDS_PER_ONCHAIN_ORDER = 3;

    // Onchain-data version.
    uint256 internal constant ONCHAIN_DATA_NONE = 0;
    uint256 internal constant ONCHAIN_DATA_VAULTS = 1;

    // The following constants are offsets of data expected in the application data.
    uint256 internal constant APP_DATA_BATCH_ID_OFFSET = 0;
    uint256 internal constant APP_DATA_PREVIOUS_BATCH_ID_OFFSET = 1;
    uint256 internal constant APP_DATA_TRANSACTIONS_DATA_OFFSET = 2;

    uint256 internal constant APP_DATA_N_WORDS_PER_CONDITIONAL_TRANSFER = 2;
}

