// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { AddressBase } from "../utils/AddressBase.sol";

abstract contract SnowPatrolBase is AccessControl, AddressBase {
    constructor(address addressRegistry) internal {
        _setAddressRegistry(addressRegistry);
    }
}
