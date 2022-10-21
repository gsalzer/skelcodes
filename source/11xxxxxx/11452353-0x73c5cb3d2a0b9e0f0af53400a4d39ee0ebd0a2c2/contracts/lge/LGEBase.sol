// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UniswapBase } from "../utils/UniswapBase.sol";

abstract contract LGEBase is UniswapBase {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    constructor(address addressRegistry) internal {
        _setAddressRegistry(addressRegistry);
    }    
}
