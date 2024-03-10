// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

interface IOracle {
    function latestAnswer() external view returns (int256);

    function decimals() external view returns (uint256);
}

