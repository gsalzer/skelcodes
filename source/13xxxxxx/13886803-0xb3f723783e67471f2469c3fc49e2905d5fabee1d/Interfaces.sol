// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface IERC20Like {

    function balanceOf(address account_) external view returns (uint256 balance_);

    function transfer(address recipient_, uint256 amount_) external returns (bool success_);

    function allowance(address owner_, address spender_) external view returns (uint256 allowance_);

    function approve(address spender_, uint256 amount_) external returns (bool success_);

    function transferFrom(address sender_, address recipient_, uint256 amount_) external returns (bool success_);

}

