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

abstract contract IMerkleVerifier {
    uint256 constant internal MAX_N_MERKLE_VERIFIER_QUERIES =  128;

    function verifyMerkle(
        uint256 channelPtr,
        uint256 queuePtr,
        bytes32 root,
        uint256 n)
        internal view virtual
        returns (bytes32 hash);
}

