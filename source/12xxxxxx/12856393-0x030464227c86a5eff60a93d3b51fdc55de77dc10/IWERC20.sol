// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./IERC20.sol";

/**
 * @dev Interface for the wrapped token
 */
interface IWERC20 is IERC20 {
    /**
     * @dev Event emmited when a user deposit WOOINU
     * @return The user, the amount deposited
     */
    event _deposit(address user, uint256 amount);

    /**
     * @dev Event emmited when a user withdraws WOOINU
     * @return The user, the amount withdrawed
     */
    event withdrawal(address user, uint256 amount);

    /**
     * @return Returns the ERC20 being used
     */
    function tokenContract() external view returns (IERC20);

    /**
     * @dev Wraps the ERC20.
     * Emits _deposit()
     * @param amount: Amount of tokens to wrap
     */
    function deposit(uint256 amount) external;

    /**
     * @dev Redeems the wrapped tokens for the ERC20. Emits withdrawal()
     * @param amount: Amount to redeem
     */
    function withdraw(uint256 amount) external;
}

