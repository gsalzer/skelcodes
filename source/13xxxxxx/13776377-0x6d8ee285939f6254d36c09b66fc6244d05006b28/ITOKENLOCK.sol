/**
* @dev Inteface for the token lock features in this contract
*/
interface ITOKENLOCK {
    /**
     * @dev Emitted when the token lock is initialized  
     * `tokenHolder` is the address the lock pertains to
     *  `amountLocked` is the amount of tokens locked 
     *  `time` is the (initial) time at which tokens were locked
     *  `unlockPeriod` is the time interval at which tokens become unlockedPerPeriod
     *  `unlockedPerPeriod` is the amount of token unlocked earch unlockPeriod
     */
    event  NewTokenLock(address tokenHolder, uint256 amountLocked, uint256 time, uint256 unlockPeriod, uint256 unlockedPerPeriod);
    /**
     * @dev Emitted when the token lock is updated  to be more strict
     * `tokenHolder` is the address the lock pertains to
     *  `amountLocked` is the amount of tokens locked 
     *  `time` is the (initial) time at which tokens were locked
     *  `unlockPeriod` is the time interval at which tokens become unlockedPerPeriod
     *  `unlockedPerPeriod` is the amount of token unlocked earch unlockPeriod
     */
    event  UpdateTokenLock(address tokenHolder, uint256 amountLocked, uint256 time, uint256 unlockPeriod, uint256 unlockedPerPeriod);
    
    /**
     * @dev Lock `baseTokensLocked_` held by the caller with `unlockedPerEpoch_` tokens unlocking each `unlockEpoch_`
     *
     *
     * Emits an {NewTokenLock} event indicating the updated terms of the token lockup.
     *
     * Requires msg.sender to:
     *
     * - Must not be a prevoius lock for this address. If so, it must be first cleared with a call to {clearLock}.
     * - Must have at least a balance of `baseTokensLocked_` to lock
     * - Must provide non-zero `unlockEpoch_`
     * - Must have at least `unlockedPerEpoch_` tokens to unlock 
     *  - `unlockedPerEpoch_` must be greater than zero
     */
    
    function newTokenLock(uint256 baseTokensLocked_, uint256 unlockEpoch_, uint256 unlockedPerEpoch_) external;
    
    /**
     * @dev Reset the lock state
     *
     * Requirements:
     *
     * - msg.sender must not have any tokens locked, currently
     */
    function clearLock() external;
    
    /**
     * @dev Returns the amount of tokens that are unlocked i.e. transferrable by `who`
     *
     */
    function balanceUnlocked(address who) external view returns (uint256 amount);
    /**
     * @dev Returns the amount of tokens that are locked and not transferrable by `who`
     *
     */
    function balanceLocked(address who) external view returns (uint256 amount);

    /**
     * @dev Reduce the amount of token unlocked each period by `subtractedValue`
     * 
     * Emits an {UpdateTokenLock} event indicating the updated terms of the token lockup.
     * 
     * Requires: 
     *  - msg.sender must have tokens currently locked
     *  - `subtractedValue` is greater than 0
     *  - cannot reduce the unlockedPerEpoch to 0
     *
     *  NOTE: As a side effect resets the baseTokensLocked and lockTime for msg.sender 
     */
    function decreaseUnlockAmount(uint256 subtractedValue) external;
    /**
     * @dev Increase the duration of the period at which tokens are unlocked by `addedValue`
     * this will have the net effect of slowing the rate at which tokens are unlocked
     * 
     * Emits an {UpdateTokenLock} event indicating the updated terms of the token lockup.
     * 
     * Requires: 
     *  - msg.sender must have tokens currently locked
     *  - `addedValue` is greater than 0
     * 
     *  NOTE: As a side effect resets the baseTokensLocked and lockTime for msg.sender 
     */
    function increaseUnlockTime(uint256 addedValue) external;
    /**
     * @dev Increase the number of tokens locked by `addedValue`
     * i.e. locks up more tokens.
     * 
     *      
     * Emits an {UpdateTokenLock} event indicating the updated terms of the token lockup.
     * 
     * Requires: 
     *  - msg.sender must have tokens currently locked
     *  - `addedValue` is greater than zero
     *  - msg.sender must have sufficient unlocked tokens to lock
     * 
     *  NOTE: As a side effect resets the baseTokensLocked and lockTime for msg.sender 
     *
     */
    function increaseTokensLocked(uint256 addedValue) external;

}
