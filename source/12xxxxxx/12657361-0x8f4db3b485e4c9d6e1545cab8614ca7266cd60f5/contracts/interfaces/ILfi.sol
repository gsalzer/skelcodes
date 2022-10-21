// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILfi is IERC20 {
    function redeem(address to, uint256 amount) external;
}

