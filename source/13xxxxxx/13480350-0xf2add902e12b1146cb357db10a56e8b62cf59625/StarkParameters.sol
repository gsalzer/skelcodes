/*
  Copyright 2019-2022 StarkWare Industries Ltd.

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
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "PrimeFieldElement0.sol";

contract StarkParameters is PrimeFieldElement0 {
    uint256 constant internal N_COEFFICIENTS = 134;
    uint256 constant internal N_INTERACTION_ELEMENTS = 6;
    uint256 constant internal MASK_SIZE = 174;
    uint256 constant internal N_ROWS_IN_MASK = 117;
    uint256 constant internal N_COLUMNS_IN_MASK = 10;
    uint256 constant internal N_COLUMNS_IN_TRACE0 = 9;
    uint256 constant internal N_COLUMNS_IN_TRACE1 = 1;
    uint256 constant internal CONSTRAINTS_DEGREE_BOUND = 2;
    uint256 constant internal N_OODS_VALUES = MASK_SIZE + CONSTRAINTS_DEGREE_BOUND;
    uint256 constant internal N_OODS_COEFFICIENTS = N_OODS_VALUES;
    uint256 constant internal MAX_FRI_STEP = 3;

    // ---------- // Air specific constants. ----------
    uint256 constant internal PUBLIC_MEMORY_STEP = 8;
    uint256 constant internal PEDERSEN_BUILTIN_RATIO = 32;
    uint256 constant internal PEDERSEN_BUILTIN_REPETITIONS = 1;
    uint256 constant internal RC_BUILTIN_RATIO = 16;
    uint256 constant internal RC_N_PARTS = 8;
    uint256 constant internal ECDSA_BUILTIN_RATIO = 2048;
    uint256 constant internal ECDSA_BUILTIN_REPETITIONS = 1;
    uint256 constant internal BITWISE__RATIO = 64;
    uint256 constant internal BITWISE__DILUTED_SPACING = 4;
    uint256 constant internal BITWISE__DILUTED_N_BITS = 16;
    uint256 constant internal LAYOUT_CODE = 42052439942391375477807157877090637012086313290658661;
    uint256 constant internal LOG_CPU_COMPONENT_HEIGHT = 4;
}
// ---------- End of auto-generated code. ----------

