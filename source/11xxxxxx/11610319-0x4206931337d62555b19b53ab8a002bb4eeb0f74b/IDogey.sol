// SPDX-License-Identifier: DOGE WORLD
pragma solidity ^0.8.0;

import "../IERC20.sol";

interface IDogey
{
    event Dogeification(IERC20 indexed doge, bool isDogey);

    function doge(uint256 _index) external view returns (IERC20);
    function isDogey(IERC20 _doge) external view returns (bool);
    function dogeCount() external view returns (uint256);
}
