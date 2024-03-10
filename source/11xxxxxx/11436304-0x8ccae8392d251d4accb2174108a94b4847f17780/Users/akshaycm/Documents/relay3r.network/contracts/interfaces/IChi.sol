// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
interface iCHI is IERC20 {
    function freeFromUpTo(address from, uint256 value) external returns (uint256);
}
