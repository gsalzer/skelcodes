// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISNAXToken is IERC20 {
    function totalAccumulated(uint256[] memory tokenIds) external view returns (uint256);
}
