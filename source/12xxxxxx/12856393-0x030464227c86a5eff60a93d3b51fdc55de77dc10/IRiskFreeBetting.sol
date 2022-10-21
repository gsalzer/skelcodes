// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @dev The interface for risk free bets
 */
interface IRiskFreeBetting {
    /**
     * @dev Event emitted when a bet is created.
     * @return The index, The URI, The reward, and The timestamp of when it ends
     */
    event betCreated(
        uint256 index,
        string metadataURI,
        uint256 reward,
        uint256 end
    );

    /**
     * @dev Event emmited when a bets result is given by the owner
     * @return The index and The winning choice
     */
    event betFinalized(uint256 index, uint256 choice);

    /**
     * @dev Event emmited when a user bets
     * @return Index of the bet, Amount betted, The user and The choice the user chose
     */
    event _bet(uint256 index, uint256 amount, address sender, uint256 choice);

    /**
     * @dev Event emmited when a user collects his reward
     * @return The user, The index of the bet, Amount rewarded
     */
    event rewardCollected(address user, uint256 index, uint256 rewardAmount);

    /**
     * @dev Struct of a bet
     * @param totalReward: The total amount of $ETH to reward to user
     * @param Choices: Amount of choices
     * @param metadataURI: A URI for a bets metadata (name, image, etc.)
     * @param end: The timestamp of when the betting period will be finished
     * @param winningChoice: After its finalized, this will show who won
     */
    struct bet__ {
        uint256 totalReward;
        uint256 choices;
        uint256 end;
        uint256 winningChoice;
        string metadataURI;
    }

    /**
     * @dev A struct to store a users bet, user to make sure the user has betted
     * to collect his reward
     * @param choice: The choice he betted
     * @param amount: Amount of tokens betted
     */
    struct _bet_ {
        uint256 choice;
        uint256 amount;
    }

    /**
     * @return Returns how much a user has betted on a bet
     * @param user: The user to check
     * @param index: The index of the bet
     */
    function betOf(address user, uint256 index)
        external
        view
        returns (_bet_ memory);

    /**
     * @return Returns all the bets that have been done + ongoing bets.
     */
    function bets() external view returns (bet__[] memory);

    /**
     * @return Returns a bet by its index
     * @param index: The index of the bet
     */
    function betByIndex(uint256 index) external view returns (bet__ memory);

    /**
     * @dev Creates a bet for people to bet on and takes a snapshot of balances(See openzeppelin@ERC20Snapshot.sol) and emits betcreated
     * @param metadataURI: The URI used to check for info like image, etc.
     * @param choices: The amount of choices allowed to bet on
     * @param end: How much seconds until the betting period ends
     */
    function createBet(
        string memory metadataURI,
        uint256 end,
        uint256 choices
    ) external payable;

    /**
     * @dev Bets on a bet and emits _bet(), gets balance from snapshot. amount can be 0 to change the choice
     * @param index: The index of the bet
     * @param amount: The amount to bet on it
     * @param __bet: What to bet on
     */
    function bet(
        uint256 index,
        uint256 amount,
        uint256 __bet
    ) external;

    /**
     * @dev Public function that returns how much unclaimed rewards a user has
     * for x index, used by collectReward()
     * @param user: The user to check rewards for
     * @param index: The index of a bet to check rewards for
     * @return Amount of unclaimed ETH in wei */
    function unclaimedReward(address user, uint256 index)
        external
        view
        returns (uint256);

    /**
     * @dev Collects the reward of winning a bet
     * @param index: The index of the bet to collect rewards from
     */
    function claimReward(uint256 index) external;

    /**
     * @dev A command that can only be used by the owner to choose the winning choice of a bet, emits betFinalized()
     * @param index: The index of the bet to finalize
     * @param winningChoice: The winningChoice of the bet
     */
    function finalizeBet(uint256 index, uint256 winningChoice) external;

     /**
     * @return The amount of tokens that have been betted on a choice
     * @param index: The index of the bet
     * @param choice: The choice of the bet
     */
     function totalBetted(uint256 index, uint256 choice) external view returns (uint256);
}

