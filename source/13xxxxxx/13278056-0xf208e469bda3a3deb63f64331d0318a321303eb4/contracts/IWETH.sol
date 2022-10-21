// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice It is the interface of functions that we use for the canonical WETH contract.
 */
abstract contract IWETH is IERC20 {
    /**
     * @notice It withdraws ETH from the contract by sending it to the caller and reducing the caller's internal balance of WETH.
     * @param amount The amount of ETH to withdraw.
     */
    function withdraw(uint256 amount) external virtual;

    /**
     * @notice It deposits ETH into the contract and increases the caller's internal balance of WETH.
     */
    function deposit() external payable virtual;
}

