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
import "MainDispatcherBase.sol";

abstract contract MainDispatcher is MainStorage, MainDispatcherBase {

    uint256 constant SUBCONTRACT_BITS = 4;

    function magicSalt() internal pure virtual returns(uint256);
    function handlerMapSection(uint256 section) internal view virtual returns(uint256);
    function expectedIdByIndex(uint256 index) internal pure virtual returns (string memory id);

    function validateSubContractIndex(uint256 index, address subContract) internal pure override {
        string memory id = SubContractor(subContract).identify();
        bytes32 hashed_expected_id = keccak256(abi.encodePacked(expectedIdByIndex(index)));
        require(
            hashed_expected_id == keccak256(abi.encodePacked(id)),
            "MISPLACED_INDEX_OR_BAD_CONTRACT_ID"
        );
    }

    function getSubContract(bytes4 selector) internal view override returns (address) {
        uint256 location = 0xFF & uint256(keccak256(abi.encodePacked(selector, magicSalt())));
        uint256 subContractIdx;
        uint256 offset = (SUBCONTRACT_BITS * location) % 256;

        // We have 64 locations in each register, hence the >>6 (i.e. location // 64).
        subContractIdx = (handlerMapSection(location >> 6) >> offset) & 0xF;
        return subContracts[subContractIdx];
    }

    function setSubContractAddress(uint256 index, address subContractAddress) internal override {
        subContracts[index] = subContractAddress;
    }
}

