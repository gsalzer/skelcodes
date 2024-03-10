// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Token is IERC20 {
    function withdraw(uint256 amount) external;
}

