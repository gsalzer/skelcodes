// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20ChildToken is IERC20 {
    function deposit(address user, bytes calldata depositData) external;
    function withdraw(uint256 amount) external;
}

