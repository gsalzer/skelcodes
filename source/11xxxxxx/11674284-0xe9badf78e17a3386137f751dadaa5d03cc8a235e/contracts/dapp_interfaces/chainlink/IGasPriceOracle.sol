// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import {IERC20} from "@gelatonetwork/core/contracts/external/IERC20.sol";

interface IGasPriceOracle {
    function latestAnswer() external view returns (int256);

    function decimals() external view returns (uint256);
}

