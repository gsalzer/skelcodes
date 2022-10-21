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
pragma solidity ^0.5.2;

/**
  StorageSlots holds the arbitrary storage slots used throughout the Proxy pattern.
  Storage address slots are a mechanism to define an arbitrary location, that will not be
  overlapped by the logical contracts.
*/
contract StorageSlots {
    /*
      Returns the address of the current implementation.
    */
    // NOLINTNEXTLINE external-function.
    function implementation() public view returns(address _implementation) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            _implementation := sload(slot)
        }
    }

    // Storage slot with the address of the current implementation.
    // The address of the slot is keccak256("StarkWare2019.implemntation-slot").
    // We need to keep this variable stored outside of the commonly used space,
    // so that it's not overrun by the logical implementation (the proxied contract).
    bytes32 internal constant IMPLEMENTATION_SLOT =
    0x177667240aeeea7e35eabe3a35e18306f336219e1386f7710a6bf8783f761b24;

    // This storage slot stores the finalization flag.
    // Once the value stored in this slot is set to non-zero
    // the proxy blocks implementation upgrades.
    // The current implementation is then referred to as Finalized.
    // Web3.solidityKeccak(['string'], ["StarkWare2019.finalization-flag-slot"]).
    bytes32 internal constant FINALIZED_STATE_SLOT =
    0x7d433c6f837e8f93009937c466c82efbb5ba621fae36886d0cac433c5d0aa7d2;
}

