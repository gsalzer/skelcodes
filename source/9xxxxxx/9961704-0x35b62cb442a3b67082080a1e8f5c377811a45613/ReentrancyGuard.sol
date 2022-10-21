pragma solidity ^0.6.4;

/**
 * @title ReentrancyGuard
 * @dev Base contract with a modifier that implements a reentrancy guard.
 */
contract ReentrancyGuard {
    /**
     * @dev Internal data to control the reentrancy.
     */
    bool internal _notEntered;

    /**
     * @dev Modifier to prevents a contract from calling itself during the function execution.
     */
    modifier nonReentrant() {
        require(_notEntered, "ReentrancyGuard:: reentry");
        _notEntered = false;
        _;
        _notEntered = true;
    }
}
