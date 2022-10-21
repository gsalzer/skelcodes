// SPDX-License-Identifier: MIT


pragma solidity ^0.6.12;

import { PatrolBase } from "../utils/PatrolBase.sol";

contract VaultBase is PatrolBase {
    constructor(address addressRegistry) 
        public
    {
        _setAddressRegistry(addressRegistry);
    }
}
