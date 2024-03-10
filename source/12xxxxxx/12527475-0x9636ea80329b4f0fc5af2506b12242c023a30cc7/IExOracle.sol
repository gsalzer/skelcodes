// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IExOracle
{
    function get(string calldata priceType, address source) external view returns (uint, uint);
}
