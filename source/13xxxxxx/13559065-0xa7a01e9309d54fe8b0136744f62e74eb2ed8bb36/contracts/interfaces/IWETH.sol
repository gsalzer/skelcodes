// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    function deposit() external payable;

    function withdraw(uint256) external;
}

