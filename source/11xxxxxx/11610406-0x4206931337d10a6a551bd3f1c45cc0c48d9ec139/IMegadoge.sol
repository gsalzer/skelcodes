// SPDX-License-Identifier: DOGE WORLD
pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../IERC20Permit.sol";

interface IMegadoge
{
    function create(IERC20 _doge, uint256 _megadogeAmount) external;
    function createFromManyDoges(IERC20[] calldata _doges, uint256[] calldata _amounts) external;
    function createWithPermit(IERC20Permit _doge, uint256 _megadogeAmount, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s) external;
}
