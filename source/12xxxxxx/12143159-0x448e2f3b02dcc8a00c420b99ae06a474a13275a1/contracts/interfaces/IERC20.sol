// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

