// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface ITokenVesting {

    /**************************/
    /*** Contract Ownership ***/
    /**************************/

    event OwnershipTransferPending(address indexed owner, address indexed pendingOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @dev Returns the owner of the contract.
    function owner() external view returns (address owner_);

    /// @dev Returns the pending owner of the contract.
    function pendingOwner() external view returns (address pendingOwner_);

    /// @dev Leaves the contract without owner, and clears the pendingOwner, if any.
    function renounceOwnership() external;

    /// @dev Allows a new account to take ownership of the contract.
    function transferOwnership(address newOwner_) external;

    /// @dev Takes ownership of the contract.
    function acceptOwnership() external;

    /*********************/
    /*** Token Vesting ***/
    /*********************/

    /**
     * @dev   Is emitted when a token vesting schedule is set for a receiver.
     * @param receiver_ The receiver of a token vesting schedule.
     */
    event VestingScheduleSet(address indexed receiver_);

    /**
     * @dev   Is emitted when the contract is funded for vesting.
     * @param totalTokens_ The total amount of tokens to be vested.
     */
    event VestingFunded(uint256 totalTokens_);

    /**
     * @dev   Is emitted when the receiver of a token vesting schedule is changed.
     * @param oldReceiver The old receiver of the token vesting schedule.
     * @param newReceiver The new receiver of the token vesting schedule.
     */
    event ReceiverChanged(address indexed oldReceiver, address indexed newReceiver);

    /**
     * @dev   Is emitted when the token vesting schedule for a receiver is killed.
     * @param receiver_      The receiver that had its token vesting schedule killed.
     * @param tokensClaimed_ The amount of tokens claimed.
     * @param destination_   The destination the token have been sent to.
     */
    event VestingKilled(address indexed receiver_, uint256 tokensClaimed_, address indexed destination_);

    /**
     * @dev   Is emitted when a receiver claims tokens from its vesting schedule.
     * @param receiver_      The receiver of a token vesting schedule.
     * @param tokensClaimed_ The amount of tokens claimed.
     * @param destination_   The destination the claimed tokens have been sent to.
     */
    event TokensClaimed(address indexed receiver_, uint256 tokensClaimed_, address indexed destination_);

    struct VestingSchedule {
        uint256 startTime;
        uint256 cliff;
        uint256 totalPeriods;
        uint256 timePerPeriod;
        uint256 totalTokens;
        uint256 tokensClaimed;
    }

    /// @dev The vesting token.
    function token() external returns (address token_);

    /// @dev The total amount of tokens being vested.
    function totalVestingsTokens() external returns (uint256 totalVestingsTokens_);

    /**
     * @dev   Returns the vesting schedule of a receiver.
     * @param receiver_      The receiver of a vesting schedule.
     */
    function vestingScheduleOf(address receiver_) external returns (
        uint256 startTime_,
        uint256 cliff_,
        uint256 totalPeriods_,
        uint256 timePerPeriod_,
        uint256 totalTokens_,
        uint256 tokensClaimed_
    );

    /**
     * @dev   Set the vesting schedules for some receivers, respectively.
     * @param receivers_ An array of receivers of vesting schedules.
     * @param vestings_  An array of vesting schedules.
     */
    function setVestingSchedules(address[] calldata receivers_, VestingSchedule[] calldata vestings_) external;

    /**
     * @dev   Fund the contact with tokens that will be vested.
     * @param totalTokens_ The amount of tokens that will be supplied to this contract.
     */
    function fundVesting(uint256 totalTokens_) external;

    /**
     * @dev   Change the receiver of an existing vesting schedule.
     * @param oldReceiver_ The old receiver address.
     * @param newReceiver_ The new receiver address.
     */
    function changeReceiver(address oldReceiver_, address newReceiver_) external;

    /**
     * @dev    Returns the amount of claimable tokens for a receiver of a vesting schedule.
     * @param  receiver_        The receiver address.
     * @return claimableTokens_ The amount of claimable tokens.
     */
    function claimableTokens(address receiver_) external view returns (uint256 claimableTokens_);

    /**
     * @dev   Claim the callers tokens of a vesting schedule.
     * @param destination_ The destination to send the tokens.
     */
    function claimTokens(address destination_) external;

    /**
     * @dev   Kill the vesting schedule for a receiver.
     * @param receiver_    The receiver address.
     * @param destination_ The destination to send the tokens.
     */
    function killVesting(address receiver_, address destination_) external;

    /*********************/
    /*** Miscellaneous ***/
    /*********************/

    /**
     * @dev   Is emitted when some ERC20 token is recovered from the contract.
     * @param token       The address of the token.
     * @param amount      The amount of token recovered.
     * @param destination The destination the token was sent to.
     */
    event RecoveredToken(address indexed token, uint256 amount, address indexed destination);

    /**
     * @dev   Recover tokens owned by the contract.
     * @param token_       The token address.
     * @param destination_ The destination to send the ETH.
     */
    function recoverToken(address token_, address destination_) external;

}

