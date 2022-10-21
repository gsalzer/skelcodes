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
pragma solidity ^0.6.12;

import "ContractInitializer.sol";
import "Governance.sol";
import "BlockDirectCall.sol";

/**
  This contract contains the code commonly needed for a contract to be deployed behind
  an upgradability proxy.
  It perform the required semantics of the proxy pattern,
  but in a generic manner.
  Instantiation of the Governance and of the ContractInitializer, that are the app specific
  part of initialization, has to be done by the using contract.
*/
abstract contract ProxySupport is Governance, BlockDirectCall, ContractInitializer {
    // The two function below (isFrozen & initialize) needed to bind to the Proxy.
    function isFrozen() external pure returns (bool) {
        return false;
    }

    /*
      The initialize() function serves as an alternative constructor for a proxied deployment.

      Flow and notes:
      1. This function cannot be called directly on the deployed contract, but only via degegate call.
      2. If the contract is already initialized, calling this function is allowed only with an empty data
    */
    function initialize(bytes calldata data) external notCalledDirectly {
        // Already initialized. Only empty init vector allowed (for upgrade).
        if (isInitialized()) {
            require(data.length == 0, "ALREADY_INITIALIZED");
            return;
        }

        // Contract was not initialized yet.
        validateInitData(data);
        initializeContractState(data);
        initGovernance();
    }
}

