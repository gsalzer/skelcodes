// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBury is IERC20 {
    function enter(
        uint256 _amount
    ) external;

    function leave(
        uint256 _share
    ) external;
}

