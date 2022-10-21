// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.4;

/**
 * @dev Partial ERC20 interface for a "non-transferable" implementation
 */
interface IERC20NoTransfer {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
}

