// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import { PatrolBase } from "../utils/PatrolBase.sol";

contract LoyaltyBase is PatrolBase {
    using SafeMath for uint256;

    constructor(address addressRegistry) 
        public
    {
        _setAddressRegistry(addressRegistry);
    }
}
