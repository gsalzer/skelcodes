// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./SafeMath.sol";
import { PatrolBase } from "./PatrolBase.sol";

contract LoyaltyBase is PatrolBase {
    using SafeMath for uint256;

    constructor(address addressRegistry) 
        public
    {
        _setAddressRegistry(addressRegistry);
    }
}
