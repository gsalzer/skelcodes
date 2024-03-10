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
// ---------- The following code was auto-generated. PLEASE DO NOT EDIT. ----------
pragma solidity ^0.5.2;

import "PrimeFieldElement0.sol";

contract StarkParameters is PrimeFieldElement0 {
    uint256 constant internal N_COEFFICIENTS = 360;
    uint256 constant internal MASK_SIZE = 193;
    uint256 constant internal N_ROWS_IN_MASK = 126;
    uint256 constant internal N_COLUMNS_IN_MASK = 18;
    uint256 constant internal CONSTRAINTS_DEGREE_BOUND = 2;
    uint256 constant internal N_OODS_VALUES = MASK_SIZE + CONSTRAINTS_DEGREE_BOUND;
    uint256 constant internal N_OODS_COEFFICIENTS = N_OODS_VALUES;
    uint256 constant internal MAX_FRI_STEP = 3;

    // ---------- // Air specific constants. ----------
    uint256 constant internal PERIODIC_HASH_POOL_STEP = 4;
    uint256 constant internal VAULTS_PERIODIC_MERKLE_HASH_STEP = 1;
    uint256 constant internal SETTLEMENT_PERIODIC_MERKLE_HASH_STEP = 1;
    uint256 constant internal ECDSA_POINTS_STEP = 128;
    uint256 constant internal VAULTS_PATH_HEIGHT = 32;
    uint256 constant internal SETTLEMENT_PATH_HEIGHT = 64;
    uint256 constant internal SETTLEMENT_PATH_LENGTH = 63;
    uint256 constant internal RANGE_CHECK_BITS = 63;
    uint256 constant internal EXPIRATION_TIMESTAMP_RANGE_CHECK_BITS = 22;
    uint256 constant internal NONCE_RANGE_CHECK_BITS = 31;
}
// ---------- End of auto-generated code. ----------

