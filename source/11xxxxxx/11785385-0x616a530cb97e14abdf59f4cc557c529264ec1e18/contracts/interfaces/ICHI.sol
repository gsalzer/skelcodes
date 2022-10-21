// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICHI is IERC20 {
    function freeFromUpTo(address _addr, uint256 _amount) external returns (uint256);
}
