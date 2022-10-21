// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./IWERC20.sol";

/**
 * @dev Interface for an ERC20 that locks users tokens
 * in exchange for other tokens.
 * Each time you wrap tokens, you should add a _lock struct for the user
 * and check if tokens are unlocked on withdrawal, on unlock emit unlock()
 */
interface ILockableERC20 is IWERC20 {
    /**
     * @dev Struct of a lock
     * @param amount: Amount of coins locked
     * @param endDate: The timestamp of when the coins get unlocked
     */
    struct _lock {
        uint256 amount;
        uint256 endDate;
    }

    /**
     * @dev Event emmited when a user unlocks his tokens
     * @return The user
     */
    event unlock(address user, uint256 amount);

    /**
     * @return Returns when a user can unlock his tokens + the amount he has locked
     * @param user: The user to check
     */
    function lock(address user) external view returns (_lock memory);

    /**
     * @return Returns how much time tokens are locked for
     */
    function lockLength() external view returns (uint256);
}

