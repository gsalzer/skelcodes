// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {AddressRegistryV2} from "contracts/registry/AddressRegistryV2.sol";

contract AddressRegistryV2Factory {
    function create() external returns (address) {
        AddressRegistryV2 logicV2 = new AddressRegistryV2();
        return address(logicV2);
    }
}

