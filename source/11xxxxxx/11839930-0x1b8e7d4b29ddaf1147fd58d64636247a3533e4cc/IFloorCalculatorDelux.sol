// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

import "./IFloorCalculator.sol";

interface IFloorCalculatorDelux is IFloorCalculator
{
    function setSubFloor(uint256 _subFloor) external;
}
