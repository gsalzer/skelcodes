// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/drafts/IERC20Permit.sol";

interface IOilerCollateral is IERC20, IERC20Permit {
    function decimals() external view returns (uint8);
}

