pragma solidity ^0.5.0;


/// @title zkSync configuration constants
/// @author Matter Labs
contract Config {

    /// @notice Notice period before activation preparation status of upgrade mode (in seconds)
    uint constant UPGRADE_NOTICE_PERIOD = 30 minutes;

    /// @notice Period after the start of preparation upgrade when contract wouldn't register new priority operations (in seconds)
    uint constant UPGRADE_PREPARATION_LOCK_PERIOD = 30 minutes;

    /// @notice ERC20 token withdrawal gas limit, used only for complete withdrawals
    uint256 constant ERC20_WITHDRAWAL_GAS_LIMIT = 250000;

    /// @notice ETH token withdrawal gas limit, used only for complete withdrawals
    uint256 constant ETH_WITHDRAWAL_GAS_LIMIT = 10000;

    /// @notice Bytes in one chunk
    uint8 constant CHUNK_BYTES = 9;

    /// @notice zkSync address length
    uint8 constant ADDRESS_BYTES = 20;

    uint8 constant PUBKEY_HASH_BYTES = 20;

    /// @notice Public key bytes length
    uint8 constant PUBKEY_BYTES = 32;

    /// @notice Ethereum signature r/s bytes length
    uint8 constant ETH_SIGN_RS_BYTES = 32;

    /// @notice Success flag bytes length
    uint8 constant SUCCESS_FLAG_BYTES = 1;

    /// @notice Max amount of tokens registered in the network (excluding ETH, which is hardcoded as tokenId = 0)
    uint16 constant MAX_AMOUNT_OF_REGISTERED_TOKENS = 128 - 1;

    /// @notice Max account id that could be registered in the network
    uint32 constant MAX_ACCOUNT_ID = (2 ** 24) - 1;

    /// @notice Expected average period of block creation
    uint256 constant BLOCK_PERIOD = 15 seconds;

    /// @notice ETH blocks verification expectation
    uint256 constant EXPECT_VERIFICATION_IN = 3 hours / BLOCK_PERIOD;

    uint256 constant NOOP_BYTES = 1 * CHUNK_BYTES;
    uint256 constant DEPOSIT_BYTES = 6 * CHUNK_BYTES;
    uint256 constant TRANSFER_TO_NEW_BYTES = 6 * CHUNK_BYTES;
    uint256 constant PARTIAL_EXIT_BYTES = 6 * CHUNK_BYTES;
    uint256 constant TRANSFER_BYTES = 2 * CHUNK_BYTES;

    /// @notice Full exit operation length
    uint256 constant FULL_EXIT_BYTES = 6 * CHUNK_BYTES;

    /// @notice OnchainWithdrawal data length
    uint256 constant ONCHAIN_WITHDRAWAL_BYTES = 1 + 20 + 2 + 16; // (uint8 addToPendingWithdrawalsQueue, address _to, uint16 _tokenId, uint128 _amount)

    /// @notice ChangePubKey operation length
    uint256 constant CHANGE_PUBKEY_BYTES = 6 * CHUNK_BYTES;

    /// @notice Expiration delta for priority request to be satisfied (in ETH blocks)
    /// NOTE: Priority expiration should be > EXPECT_VERIFICATION_IN, otherwise incorrect block with priority op could not be reverted.
    uint256 constant PRIORITY_EXPIRATION = 6 days / BLOCK_PERIOD;

    /// @notice Maximum number of priority request to clear during verifying the block
    /// @dev Cause deleting storage slots cost 5k gas per each slot it's unprofitable to clear too many slots
    /// @dev Value based on the assumption of ~750k gas cost of verifying and 5 used storage slots per PriorityOperation structure
    uint64 constant MAX_PRIORITY_REQUESTS_TO_DELETE_IN_VERIFY = 6;

}

