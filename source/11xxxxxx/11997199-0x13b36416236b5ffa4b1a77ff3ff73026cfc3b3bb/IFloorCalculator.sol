// SPDX-License-Identifier: P-P-P-PONZO!!!
pragma solidity ^0.7.4;

import "./IERC20.sol";

interface IFloorCalculator
{
    function calculateSubFloor(IERC20 wrappedToken, IERC20 backingToken) external view returns (uint256);
}
