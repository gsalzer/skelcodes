// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import './IERC20.sol';

interface IBuyBurner {
    function approveExchange(IERC20[] calldata _tokens) external;
    receive() payable external;
    function buyBurn(IERC20[] calldata _tokens) external;
}

