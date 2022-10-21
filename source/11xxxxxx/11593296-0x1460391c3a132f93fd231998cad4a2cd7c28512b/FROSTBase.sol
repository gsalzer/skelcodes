// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

// import { ERC20 } from "../utils/ERC20/ERC20.sol";

import { FROSTToken } from "./FROSTToken.sol";
import { PatrolBase } from "./PatrolBase.sol";

abstract contract FROSTBase is PatrolBase, FROSTToken {
    constructor(
        address addressRegistry,
        string memory name_, 
        string memory symbol_
    ) 
        public
        FROSTToken(name_, symbol_)
    {
        _setAddressRegistry(addressRegistry);
    }
}
