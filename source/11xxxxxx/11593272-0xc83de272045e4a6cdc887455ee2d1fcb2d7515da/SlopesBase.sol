// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { IERC20 } from "./IERC20.sol";
import { SafeERC20 } from "./SafeERC20.sol";
import { SafeMath } from "./SafeMath.sol";
import { LendingPoolBase } from "./LendingPoolBase.sol";

abstract contract SlopesBase is LendingPoolBase {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    constructor(address addressRegistry) internal {
        _setAddressRegistry(addressRegistry);
    }
}
