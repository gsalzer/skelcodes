// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVesperPool is IERC20 {
    function withdraw(uint256 _amount) external;

    function deposit(uint256) external;

    function token() external view returns (IERC20);
}

