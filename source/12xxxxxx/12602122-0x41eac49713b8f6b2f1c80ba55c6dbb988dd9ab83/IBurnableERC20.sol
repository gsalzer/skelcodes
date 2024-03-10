// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import {IERC20} from "IERC20.sol";

interface IBurnableERC20 is IERC20 {
    function burn(uint256 amount) external;
}

