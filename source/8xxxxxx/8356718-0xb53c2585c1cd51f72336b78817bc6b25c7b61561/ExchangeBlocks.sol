/*

  Copyright 2017 Loopring Project Ltd (Loopring Foundation).

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
pragma solidity ^0.5.11;


/// @title Ownable
/// @author Brecht Devos - <brecht@loopring.org>
/// @dev The Ownable contract has an owner address, and provides basic
///      authorization control functions, this simplifies the implementation of
///      "user permissions".
contract Ownable
{
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @dev The Ownable constructor sets the original `owner` of the contract
    ///      to the sender.
    constructor()
        public
    {
        owner = msg.sender;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner()
    {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    /// @dev Allows the current owner to transfer control of the contract to a
    ///      new owner.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(
        address newOwner
        )
        public
        onlyOwner
    {
        require(newOwner != address(0), "ZERO_ADDRESS");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership()
        public
        onlyOwner
    {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}


/// @title Claimable
/// @author Brecht Devos - <brecht@loopring.org>
/// @dev Extension for the Ownable contract, where the ownership needs
///      to be claimed. This allows the new owner to accept the transfer.
contract Claimable is Ownable
{
    address public pendingOwner;

    /// @dev Modifier throws if called by any account other than the pendingOwner.
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "UNAUTHORIZED");
        _;
    }

    /// @dev Allows the current owner to set the pendingOwner address.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(
        address newOwner
        )
        public
        onlyOwner
    {
        require(newOwner != address(0) && newOwner != owner, "INVALID_ADDRESS");
        pendingOwner = newOwner;
    }

    /// @dev Allows the pendingOwner address to finalize the transfer.
    function claimOwnership()
        public
        onlyPendingOwner
    {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

/// @title ReentrancyGuard
/// @author Brecht Devos - <brecht@loopring.org>
/// @dev Exposes a modifier that guards a function against reentrancy
///      Changing the value of the same storage value multiple times in a transaction
///      is cheap (starting from Istanbul) so there is no need to minimize
///      the number of times the value is changed
contract ReentrancyGuard
{
    //The default value must be 0 in order to work behind a proxy.
    uint private _guardValue;

    // Use this modifier on a function to prevent reentrancy
    modifier nonReentrant()
    {
        // Check if the guard value has its original value
        require(_guardValue == 0, "REENTRANCY");

        // Set the value to something else
        _guardValue = 1;

        // Function body
        _;

        // Set the value back
        _guardValue = 0;
    }
}

/// @title Utility Functions for bytes
/// @author Daniel Wang - <daniel@loopring.org>
library BytesUtil
{
    function bytesToBytes32(
        bytes memory b,
        uint  offset
        )
        internal
        pure
        returns (bytes32)
    {
        return bytes32(bytesToUintX(b, offset, 32));
    }

    function bytesToUint(
        bytes memory b,
        uint  offset
        )
        internal
        pure
        returns (uint)
    {
        return bytesToUintX(b, offset, 32);
    }

    function bytesToAddress(
        bytes memory b,
        uint  offset
        )
        internal
        pure
        returns (address)
    {
        return address(bytesToUintX(b, offset, 20) & 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    }

    function bytesToUint16(
        bytes memory b,
        uint  offset
        )
        internal
        pure
        returns (uint16)
    {
        return uint16(bytesToUintX(b, offset, 2) & 0xFFFF);
    }

    function bytesToUintX(
        bytes memory b,
        uint  offset,
        uint  numBytes
        )
        private
        pure
        returns (uint data)
    {
        require(b.length >= offset + numBytes, "INVALID_SIZE");
        assembly {
            data := mload(add(add(b, numBytes), offset))
        }
    }

    function subBytes(
        bytes memory b,
        uint  offset
        )
        internal
        pure
        returns (bytes memory data)
    {
        require(b.length >= offset + 32, "INVALID_SIZE");
        assembly {
            data := add(add(b, 32), offset)
        }
    }

    function fastSHA256(
        bytes memory data
        )
        internal
        view
        returns (bytes32)
    {
        bytes32[] memory result = new bytes32[](1);
        bool success;
        assembly {
             let ptr := add(data, 32)
             success := staticcall(sub(gas, 2000), 2, ptr, mload(data), add(result, 32), 32)
        }
        require(success, "SHA256_FAILED");
        return result[0];
    }
}

/// @title Utility Functions for uint
/// @author Daniel Wang - <daniel@loopring.org>
library MathUint
{
    function mul(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a * b;
        require(a == 0 || c / a == b, "MUL_OVERFLOW");
    }

    function sub(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint)
    {
        require(b <= a, "SUB_UNDERFLOW");
        return a - b;
    }

    function add(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a + b;
        require(c >= a, "ADD_OVERFLOW");
    }

    function decodeFloat(
        uint f
        )
        internal
        pure
        returns (uint value)
    {
        uint numBitsMantissa = 23;
        uint exponent = f >> numBitsMantissa;
        uint mantissa = f & ((1 << numBitsMantissa) - 1);
        value = mantissa * (10 ** exponent);
    }
}

/// @title IBlockVerifier
/// @author Brecht Devos - <brecht@loopring.org>
contract IBlockVerifier
{
    // -- Events --

    event CircuitRegistered(
        uint8  indexed blockType,
        bool           onchainDataAvailability,
        uint16         blockSize,
        uint8          blockVersion
    );

    event CircuitDisabled(
        uint8  indexed blockType,
        bool           onchainDataAvailability,
        uint16         blockSize,
        uint8          blockVersion
    );

    // -- Public functions --

    /// @dev Sets the verifying key for the specified circuit.
    ///      Every block permutation needs its own circuit and thus its own set of
    ///      verification keys. Only a limited number of block sizes per block
    ///      type are supported.
    /// @param blockType The type of the block See @BlockType
    /// @param onchainDataAvailability True if the block expects onchain
    ///        data availability data as public input, false otherwise
    /// @param blockSize The number of requests handled in the block
    /// @param blockVersion The block version (i.e. which circuit version needs to be used)
    /// @param vk The verification key
    function registerCircuit(
        uint8    blockType,
        bool     onchainDataAvailability,
        uint16   blockSize,
        uint8    blockVersion,
        uint[18] calldata vk
        )
        external;

    /// @dev Disables the use of the specified circuit.
    ///      This will stop NEW blocks from using the given circuit, blocks that were already committed
    ///      can still be verified.
    /// @param blockType The type of the block See @BlockType
    /// @param onchainDataAvailability True if the block expects onchain
    ///        data availability data as public input, false otherwise
    /// @param blockSize The number of requests handled in the block
    /// @param blockVersion The block version (i.e. which circuit version needs to be used)
    function disableCircuit(
        uint8  blockType,
        bool   onchainDataAvailability,
        uint16 blockSize,
        uint8  blockVersion
        )
        external;

    /// @dev Verify blocks with the given public data and proofs.
    ///      Verifying a block makes sure all requests handled in the block
    ///      are correctly handled by the operator.
    /// @param blockType The type of block See @BlockType
    /// @param onchainDataAvailability True if the block expects onchain
    ///        data availability data as public input, false otherwise
    /// @param blockSize The number of requests handled in the block
    /// @param blockVersion The block version (i.e. which circuit version needs to be used)
    /// @param publicInputs The hash of all the public data of the blocks
    /// @param proofs The ZK proofs proving that the blocks are correct
    /// @return True if the block is valid, false otherwise
    function verifyProofs(
        uint8  blockType,
        bool   onchainDataAvailability,
        uint16 blockSize,
        uint8  blockVersion,
        uint[] calldata publicInputs,
        uint[] calldata proofs
        )
        external
        view
        returns (bool);

    /// @dev Checks if a circuit with the specified parameters is registered.
    /// @param blockType The type of the block See @BlockType
    /// @param onchainDataAvailability True if the block expects onchain
    ///        data availability data as public input, false otherwise
    /// @param blockSize The number of requests handled in the block
    /// @param blockVersion The block version (i.e. which circuit version needs to be used)
    /// @return True if the circuit is registered, false otherwise
    function isCircuitRegistered(
        uint8  blockType,
        bool   onchainDataAvailability,
        uint16 blockSize,
        uint8  blockVersion
        )
        external
        view
        returns (bool);

    /// @dev Checks if a circuit can still be used to commit new blocks.
    /// @param blockType The type of the block See @BlockType
    /// @param onchainDataAvailability True if the block expects onchain
    ///        data availability data as public input, false otherwise
    /// @param blockSize The number of requests handled in the block
    /// @param blockVersion The block version (i.e. which circuit version needs to be used)
    /// @return True if the circuit is enabled, false otherwise
    function isCircuitEnabled(
        uint8  blockType,
        bool   onchainDataAvailability,
        uint16 blockSize,
        uint8  blockVersion
        )
        external
        view
        returns (bool);
}

/// @title IDecompressor
/// @author Brecht Devos - <brecht@loopring.org>
contract IDecompressor
{
    /// @dev Decompresses the data
    /// @param data The compressed data
    /// @return decompressedData The decompressed data
    function decompress(
        bytes calldata data
        )
        external
        pure
        returns (bytes memory decompressedData);
}

/// @title ILoopring
/// @author Daniel Wang  - <daniel@loopring.org>
contract ILoopring is Claimable, ReentrancyGuard
{
    address public protocolRegistry;
    address public lrcAddress;
    uint    public exchangeCreationCostLRC;

    event ExchangeInitialized(
        uint    indexed exchangeId,
        address indexed exchangeAddress,
        address indexed owner,
        address         operator,
        bool            onchainDataAvailability
    );

    /// @dev Initialize and register an exchange.
    ///      This function should only be callabled by the protocolRegistry contract.
    ///      Also note that this function can only be called once per exchange instance.
    /// @param  exchangeAddress The address of the exchange to initialize and register.
    /// @param  exchangeId The unique exchange id.
    /// @param  owner The owner of the exchange.
    /// @param  operator The operator of the exchange.
    /// @param  onchainDataAvailability True if "Data Availability" is turned on for this
    ///         exchange. Note that this value can not be changed once the exchange is initialized.
    /// @return exchangeId The id of the exchange.
    function initializeExchange(
        address exchangeAddress,
        uint    exchangeId,
        address owner,
        address payable operator,
        bool    onchainDataAvailability
        )
        external;
}



/// @title ILoopringV3
/// @author Brecht Devos - <brecht@loopring.org>
/// @author Daniel Wang  - <daniel@loopring.org>
contract ILoopringV3 is ILoopring
{
    // == Events ==

    event ExchangeStakeDeposited(
        uint    indexed exchangeId,
        uint            amount
    );

    event ExchangeStakeWithdrawn(
        uint    indexed exchangeId,
        uint            amount
    );

    event ExchangeStakeBurned(
        uint    indexed exchangeId,
        uint            amount
    );

    event ProtocolFeeStakeDeposited(
        uint    indexed exchangeId,
        uint            amount
    );

    event ProtocolFeeStakeWithdrawn(
        uint    indexed exchangeId,
        uint            amount
    );

    event SettingsUpdated(
        uint            time
    );

    // == Public Variables ==
    struct Exchange
    {
        address exchangeAddress;
        uint    exchangeStake;
        uint    protocolFeeStake;
    }

    mapping (uint => Exchange) internal exchanges;

    uint    public totalStake;

    address public wethAddress;
    address public exchangeDeployerAddress;
    address public blockVerifierAddress;
    address public downtimeCostCalculator;
    uint    public maxWithdrawalFee;
    uint    public withdrawalFineLRC;
    uint    public tokenRegistrationFeeLRCBase;
    uint    public tokenRegistrationFeeLRCDelta;
    uint    public minExchangeStakeWithDataAvailability;
    uint    public minExchangeStakeWithoutDataAvailability;
    uint    public revertFineLRC;
    uint8   public minProtocolTakerFeeBips;
    uint8   public maxProtocolTakerFeeBips;
    uint8   public minProtocolMakerFeeBips;
    uint8   public maxProtocolMakerFeeBips;
    uint    public targetProtocolTakerFeeStake;
    uint    public targetProtocolMakerFeeStake;

    address payable public protocolFeeVault;

    // == Public Functions ==
    /// @dev Update the global exchange settings.
    ///      This function can only be called by the owner of this contract.
    ///
    ///      Warning: these new values will be used by existing and
    ///      new Loopring exchanges.
    function updateSettings(
        address payable _protocolFeeVault,   // address(0) not allowed
        address _blockVerifierAddress,       // address(0) not allowed
        address _downtimeCostCalculator,     // address(0) allowed
        uint    _exchangeCreationCostLRC,
        uint    _maxWithdrawalFee,
        uint    _tokenRegistrationFeeLRCBase,
        uint    _tokenRegistrationFeeLRCDelta,
        uint    _minExchangeStakeWithDataAvailability,
        uint    _minExchangeStakeWithoutDataAvailability,
        uint    _revertFineLRC,
        uint    _withdrawalFineLRC
        )
        external;

    /// @dev Update the global protocol fee settings.
    ///      This function can only be called by the owner of this contract.
    ///
    ///      Warning: these new values will be used by existing and
    ///      new Loopring exchanges.
    function updateProtocolFeeSettings(
        uint8 _minProtocolTakerFeeBips,
        uint8 _maxProtocolTakerFeeBips,
        uint8 _minProtocolMakerFeeBips,
        uint8 _maxProtocolMakerFeeBips,
        uint  _targetProtocolTakerFeeStake,
        uint  _targetProtocolMakerFeeStake
        )
        external;

    /// @dev Returns whether the Exchange has staked enough to commit blocks
    ///      Exchanges with on-chain data-availaiblity need to stake at least
    ///      minExchangeStakeWithDataAvailability, exchanges without
    ///      data-availability need to stake at least
    ///      minExchangeStakeWithoutDataAvailability.
    /// @param exchangeId The id of the exchange
    /// @param onchainDataAvailability True if the exchange has on-chain
    ///        data-availability, else false
    /// @return True if the exchange has staked enough, else false
    function canExchangeCommitBlocks(
        uint exchangeId,
        bool onchainDataAvailability
        )
        external
        view
        returns (bool);

    /// @dev Get the amount of staked LRC for an exchange.
    /// @param exchangeId The id of the exchange
    /// @return stakedLRC The amount of LRC
    function getExchangeStake(
        uint exchangeId
        )
        public
        view
        returns (uint stakedLRC);

    /// @dev Burn a certain amount of staked LRC for a specific exchange.
    ///      This function is meant to be called only from exchange contracts.
    /// @param  exchangeId The id of the exchange
    /// @return burnedLRC The amount of LRC burned. If the amount is greater than
    ///         the staked amount, all staked LRC will be burned.
    function burnExchangeStake(
        uint exchangeId,
        uint amount
        )
        external
        returns (uint burnedLRC);

    /// @dev Stake more LRC for an exchange.
    /// @param  exchangeId The id of the exchange
    /// @param  amountLRC The amount of LRC to stake
    /// @return stakedLRC The total amount of LRC staked for the exchange
    function depositExchangeStake(
        uint exchangeId,
        uint amountLRC
        )
        external
        returns (uint stakedLRC);

    /// @dev Withdraw a certain amount of staked LRC for an exchange to the given address.
    ///      This function is meant to be called only from within exchange contracts.
    /// @param  exchangeId The id of the exchange
    /// @param  recipient The address to receive LRC
    /// @param  requestedAmount The amount of LRC to withdraw
    /// @return stakedLRC The amount of LRC withdrawn
    function withdrawExchangeStake(
        uint    exchangeId,
        address recipient,
        uint    requestedAmount
        )
        external
        returns (uint amount);

    /// @dev Stake more LRC for an exchange.
    /// @param  exchangeId The id of the exchange
    /// @param  amountLRC The amount of LRC to stake
    /// @return stakedLRC The total amount of LRC staked for the exchange
    function depositProtocolFeeStake(
        uint exchangeId,
        uint amountLRC
        )
        external
        returns (uint stakedLRC);

    /// @dev Withdraw a certain amount of staked LRC for an exchange to the given address.
    ///      This function is meant to be called only from within exchange contracts.
    /// @param  exchangeId The id of the exchange
    /// @param  recipient The address to receive LRC
    /// @param  amount The amount of LRC to withdraw
    function withdrawProtocolFeeStake(
        uint    exchangeId,
        address recipient,
        uint    amount
        )
        external;

    /// @dev Get the protocol fee values for an exchange.
    /// @param exchangeId The id of the exchange
    /// @param onchainDataAvailability True if the exchange has on-chain
    ///        data-availability, else false
    /// @return takerFeeBips The protocol taker fee
    /// @return makerFeeBips The protocol maker fee
    function getProtocolFeeValues(
        uint exchangeId,
        bool onchainDataAvailability
        )
        external
        view
        returns (
            uint8 takerFeeBips,
            uint8 makerFeeBips
        );

    /// @dev Returns the exchange's protocol fee stake.
    /// @param  exchangeId The exchange's id.
    /// @return protocolFeeStake The exchange's protocol fee stake.
    function getProtocolFeeStake(
        uint exchangeId
        )
        external
        view
        returns (uint protocolFeeStake);
}

/// @title ExchangeData
/// @dev All methods in this lib are internal, therefore, there is no need
///      to deploy this library independently.
/// @author Daniel Wang  - <daniel@loopring.org>
/// @author Brecht Devos - <brecht@loopring.org>
library ExchangeData
{
    // -- Enums --
    enum BlockType
    {
        RING_SETTLEMENT,
        DEPOSIT,
        ONCHAIN_WITHDRAWAL,
        OFFCHAIN_WITHDRAWAL,
        ORDER_CANCELLATION,
        TRANSFER
    }

    enum BlockState
    {
        // This value should never be seen onchain, but we want to reserve 0 so the
        // relayer can use this as the default for new blocks.
        NEW,            // = 0

        // The default state when a new block is included onchain.
        COMMITTED,      // = 1

        // A valid ZK proof has been submitted for this block.
        // The genesis block is VERIFIED by default.
        VERIFIED        // = 2
    }

    // -- Structs --
    struct Account
    {
        address owner;

        // pubKeyX and pubKeyY put together is the EdDSA public trading key. Users or their
        // wallet software are supposed to manage the corresponding private key for signing
        // orders and offchain requests.
        //
        // We use EdDSA because it is more circuit friendly than ECDSA. In later versions
        // we may switch back to ECDSA, then we will not need such a dedicated tradig key-pair.
        //
        // We split the public key into two uint to make it more circuit friendly.
        uint    pubKeyX;
        uint    pubKeyY;
    }

    struct Token
    {
        address token;
        bool    depositDisabled;
    }

    struct ProtocolFeeData
    {
        uint32 timestamp;
        uint8 takerFeeBips;
        uint8 makerFeeBips;
        uint8 previousTakerFeeBips;
        uint8 previousMakerFeeBips;
    }

    // This is the (virtual) block an operator needs to submit onchain to maintain the
    // per-exchange (virtual) blockchain.
    struct Block
    {
        // The merkle root of the offchain data stored in a merkle tree. The merkle tree
        // stores balances for users using an account model.
        bytes32 merkleRoot;

        // The hash of all the public data sent in commitBlock. Committing a block
        // is decoupled from the verification of a block, but we don't want to send
        // the (often) large amount of data (certainly with onchain data availability) again
        // when verifying the proof, so we hash all that data onchain in commitBlock so that we
        // can use it in verifyBlock to verify the block. This also makes the verification cheaper
        // onchain because we only have this single public input.
        bytes32 publicDataHash;

        // The current state of the block. See @BlockState for more information.
        BlockState state;

        // The type of the block (i.e. what kind of requests were processed).
        // See @BlockType for more information.
        BlockType blockType;

        // The number of requests processed in the block. Only a limited number of permutations
        // are available for each block type (because each will need a different circuit
        // and thus different verification key onchain). Use IBlockVerifier.canVerify to find out if
        // the block is supported.
        uint16 blockSize;

        // The block version (i.e. what circuit version needs to be used to verify the block).
        uint8  blockVersion;

        // The time the block was created.
        uint32 timestamp;

        // The number of onchain deposit requests that have been processed
        // up to and including this block.
        uint32 numDepositRequestsCommitted;

        // The number of onchain withdrawal requests that have been processed
        // up to and including this block.
        uint32 numWithdrawalRequestsCommitted;

        // Stores whether the fee earned by the operator for processing onchain requests
        // is withdrawn or not.
        bool   blockFeeWithdrawn;

        // Number of withdrawals distributed using `distributeWithdrawals`
        uint16 numWithdrawalsDistributed;

        // The approved withdrawal data. Needs to be stored onchain so this data is available
        // once the block is finalized and the funds can be withdrawn using the info stored
        // in this data.
        // For every withdrawal (there are 'blockSize' withdrawals),
        // stored sequentially after each other:
        //    - Token ID: 1 bytes
        //    - Account ID: 2,5 bytes
        //    - Amount: 3,5 bytes
        bytes  withdrawals;
    }

    // Represents the post-state of an onchain deposit/withdrawal request. We can visualize
    // a deposit request-chain and a withdrawal request-chain, each of which is
    // composed of such Request objects. Please refer to the design doc for more details.
    struct Request
    {
        bytes32 accumulatedHash;
        uint    accumulatedFee;
        uint32  timestamp;
    }

    // Represents an onchain deposit request.  `tokenID` being `0x0` means depositing Ether.
    struct Deposit
    {
        uint24 accountID;
        uint16 tokenID;
        uint96 amount;
    }

    function SNARK_SCALAR_FIELD() internal pure returns (uint) {
        // This is the prime number that is used for the alt_bn128 elliptic curve, see EIP-196.
        return 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    }

    function MAX_PROOF_GENERATION_TIME_IN_SECONDS() internal pure returns (uint32) { return 1 hours; }
    function MAX_GAP_BETWEEN_FINALIZED_AND_VERIFIED_BLOCKS() internal pure returns (uint32) { return 2500; }
    function MAX_OPEN_DEPOSIT_REQUESTS() internal pure returns (uint16) { return 1024; }
    function MAX_OPEN_WITHDRAWAL_REQUESTS() internal pure returns (uint16) { return 1024; }
    function MAX_AGE_UNFINALIZED_BLOCK_UNTIL_WITHDRAW_MODE() internal pure returns (uint32) { return 1 days; }
    function MAX_AGE_REQUEST_UNTIL_FORCED() internal pure returns (uint32) { return 15 minutes; }
    function MAX_AGE_REQUEST_UNTIL_WITHDRAW_MODE() internal pure returns (uint32) { return 1 days; }
    function MAX_TIME_IN_SHUTDOWN_BASE() internal pure returns (uint32) { return 1 days; }
    function MAX_TIME_IN_SHUTDOWN_DELTA() internal pure returns (uint32) { return 15 seconds; }
    function TIMESTAMP_HALF_WINDOW_SIZE_IN_SECONDS() internal pure returns (uint32) { return 10 minutes; }
    function MAX_NUM_TOKENS() internal pure returns (uint) { return 2 ** 8; }
    function MAX_NUM_ACCOUNTS() internal pure returns (uint) { return 2 ** 20 - 1; }
    function MAX_TIME_TO_DISTRIBUTE_WITHDRAWALS() internal pure returns (uint32) { return 2 hours; }
    function FEE_BLOCK_FINE_START_TIME() internal pure returns (uint32) { return 5 minutes; }
    function FEE_BLOCK_FINE_MAX_DURATION() internal pure returns (uint32) { return 30 minutes; }
    function MIN_GAS_TO_DISTRIBUTE_WITHDRAWALS() internal pure returns (uint32) { return 60000; }
    function MIN_AGE_PROTOCOL_FEES_UNTIL_UPDATED() internal pure returns (uint32) { return 1 days; }
    function GAS_LIMIT_SEND_TOKENS() internal pure returns (uint32) { return 30000; }

    // Represents the entire exchange state except the owner of the exchange.
    struct State
    {
        uint    id;
        uint    exchangeCreationTimestamp;
        address payable operator; // The only address that can submit new blocks.
        bool    onchainDataAvailability;

        ILoopringV3    loopring;
        IBlockVerifier blockVerifier;

        address lrcAddress;

        uint    totalTimeInMaintenanceSeconds;
        uint    numDowntimeMinutes;
        uint    downtimeStart;

        address addressWhitelist;
        uint    accountCreationFeeETH;
        uint    accountUpdateFeeETH;
        uint    depositFeeETH;
        uint    withdrawalFeeETH;

        Block[]     blocks;
        Token[]     tokens;
        Account[]   accounts;
        Deposit[]   deposits;
        Request[]   depositChain;
        Request[]   withdrawalChain;

        // A map from the account owner to accountID + 1
        mapping (address => uint24) ownerToAccountId;
        mapping (address => uint16) tokenToTokenId;

        // A map from an account owner to a token to if the balance is withdrawn
        mapping (address => mapping (address => bool)) withdrawnInWithdrawMode;

        // A map from token address to their accumulated balances
        mapping (address => uint) tokenBalances;

        // A block's state will become FINALIZED when and only when this block is VERIFIED
        // and all previous blocks in the chain have become FINALIZED.
        // The genesis block is FINALIZED by default.
        uint numBlocksFinalized;

        // Cached data for the protocol fee
        ProtocolFeeData protocolFeeData;

        // Time when the exchange was shutdown
        uint shutdownStartTime;
    }
}

/// @title ExchangeMode.
/// @dev All methods in this lib are internal, therefore, there is no need
///      to deploy this library independently.
/// @author Brecht Devos - <brecht@loopring.org>
/// @author Daniel Wang  - <daniel@loopring.org>
library ExchangeMode
{
    using MathUint  for uint;

    function isInWithdrawalMode(
        ExchangeData.State storage S
        )
        internal // inline call
        view
        returns (bool result)
    {
        result = false;
        ExchangeData.Block storage currentBlock = S.blocks[S.blocks.length - 1];

        // Check if there's a deposit request that's too old
        if (currentBlock.numDepositRequestsCommitted < S.depositChain.length) {
            uint32 requestTimestamp = S.depositChain[currentBlock.numDepositRequestsCommitted].timestamp;
            result = requestTimestamp < now.sub(ExchangeData.MAX_AGE_REQUEST_UNTIL_WITHDRAW_MODE());
        }

        // Check if there's a withdrawal request that's too old
        if (result == false && currentBlock.numWithdrawalRequestsCommitted < S.withdrawalChain.length) {
            uint32 requestTimestamp = S.withdrawalChain[currentBlock.numWithdrawalRequestsCommitted].timestamp;
            result = requestTimestamp < now.sub(ExchangeData.MAX_AGE_REQUEST_UNTIL_WITHDRAW_MODE());
        }

        // Check if there's an unfinalized block that's too old
        if (result == false) {
            result = isAnyUnfinalizedBlockTooOld(S);
        }

        // Check if we're longer in a non-initial state while shutdown than allowed
        if (result == false && isShutdown(S) && !isInInitialState(S)) {
            // The max amount of time an exchange can be in shutdown is
            // MAX_TIME_IN_SHUTDOWN_BASE + (accounts.length * MAX_TIME_IN_SHUTDOWN_DELTA)
            uint maxTimeInShutdown = ExchangeData.MAX_TIME_IN_SHUTDOWN_BASE();
            maxTimeInShutdown = maxTimeInShutdown.add(S.accounts.length.mul(ExchangeData.MAX_TIME_IN_SHUTDOWN_DELTA()));
            result = now > S.shutdownStartTime.add(maxTimeInShutdown);
        }
    }

    function isShutdown(
        ExchangeData.State storage S
        )
        internal // inline call
        view
        returns (bool)
    {
        return S.shutdownStartTime > 0;
    }

    function isInMaintenance(
        ExchangeData.State storage S
        )
        internal // inline call
        view
        returns (bool)
    {
        return S.downtimeStart != 0 && getNumDowntimeMinutesLeft(S) > 0;
    }

    function isInInitialState(
        ExchangeData.State storage S
        )
        internal // inline call
        view
        returns (bool)
    {
        ExchangeData.Block storage firstBlock = S.blocks[0];
        ExchangeData.Block storage lastBlock = S.blocks[S.blocks.length - 1];
        return (S.blocks.length == S.numBlocksFinalized) &&
            (lastBlock.numDepositRequestsCommitted == S.depositChain.length) &&
            (lastBlock.merkleRoot == firstBlock.merkleRoot);
    }

    function areUserRequestsEnabled(
        ExchangeData.State storage S
        )
        internal // inline call
        view
        returns (bool)
    {
        // User requests are possible when the exchange is not in maintenance mode,
        // the exchange hasn't been shutdown, and the exchange isn't in withdrawal mode
        return !isInMaintenance(S) && !isShutdown(S) && !isInWithdrawalMode(S);
    }

    function isAnyUnfinalizedBlockTooOld(
        ExchangeData.State storage S
        )
        internal // inline call
        view
        returns (bool)
    {
        if (S.numBlocksFinalized < S.blocks.length) {
            uint32 blockTimestamp = S.blocks[S.numBlocksFinalized].timestamp;
            return blockTimestamp < now.sub(ExchangeData.MAX_AGE_UNFINALIZED_BLOCK_UNTIL_WITHDRAW_MODE());
        } else {
            return false;
        }
    }

    function getNumDowntimeMinutesLeft(
        ExchangeData.State storage S
        )
        internal // inline call
        view
        returns (uint)
    {
        if (S.downtimeStart == 0) {
            return S.numDowntimeMinutes;
        } else {
            // Calculate how long (in minutes) the exchange is in maintenance
            uint numDowntimeMinutesUsed = now.sub(S.downtimeStart) / 60;
            if (S.numDowntimeMinutes > numDowntimeMinutesUsed) {
                return S.numDowntimeMinutes.sub(numDowntimeMinutesUsed);
            } else {
                return 0;
            }
        }
    }
}

/// @title ExchangeBlocks.
/// @author Brecht Devos - <brecht@loopring.org>
/// @author Daniel Wang  - <daniel@loopring.org>
library ExchangeBlocks
{
    using BytesUtil         for bytes;
    using MathUint          for uint;
    using ExchangeMode      for ExchangeData.State;

    event BlockCommitted(
        uint    indexed blockIdx,
        bytes32 indexed publicDataHash
    );

    event BlockFinalized(
        uint    indexed blockIdx
    );

    event BlockVerified(
        uint    indexed blockIdx
    );

    event Revert(
        uint    indexed blockIdx
    );

    event ProtocolFeesUpdated(
        uint8 takerFeeBips,
        uint8 makerFeeBips,
        uint8 previousTakerFeeBips,
        uint8 previousMakerFeeBips
    );

    function commitBlock(
        ExchangeData.State storage S,
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion,
        bytes  calldata data,
        bytes  calldata /*offchainData*/
        )
        external
    {
        commitBlockInternal(
            S,
            ExchangeData.BlockType(blockType),
            blockSize,
            blockVersion,
            data
        );
    }

    function verifyBlocks(
        ExchangeData.State storage S,
        uint[] calldata blockIndices,
        uint[] calldata proofs
        )
        external
    {
        // Exchange cannot be in withdrawal mode
        require(!S.isInWithdrawalMode(), "INVALID_MODE");

        // Check input data
        require(blockIndices.length > 0, "INVALID_INPUT_ARRAYS");
        require(proofs.length % 8 == 0, "INVALID_PROOF_ARRAY");
        require(proofs.length / 8 == blockIndices.length, "INVALID_INPUT_ARRAYS");

        uint[] memory publicInputs = new uint[](blockIndices.length);
        uint16 blockSize;
        ExchangeData.BlockType blockType;
        uint8 blockVersion;

        for (uint i = 0; i < blockIndices.length; i++) {
            uint blockIdx = blockIndices[i];

            require(blockIdx < S.blocks.length, "INVALID_BLOCK_IDX");
            ExchangeData.Block storage specifiedBlock = S.blocks[blockIdx];
            require(
                specifiedBlock.state == ExchangeData.BlockState.COMMITTED,
                "BLOCK_VERIFIED_ALREADY"
            );

            // Check if the proof for this block is too early
            // We limit the gap between the last finalized block and the last verified block to limit
            // the number of blocks that can become finalized when a single block is verified
            require(
                blockIdx < S.numBlocksFinalized + ExchangeData.MAX_GAP_BETWEEN_FINALIZED_AND_VERIFIED_BLOCKS(),
                "PROOF_TOO_EARLY"
            );

            // Check if we still accept a proof for this block
            require(
                now <= specifiedBlock.timestamp + ExchangeData.MAX_PROOF_GENERATION_TIME_IN_SECONDS(),
                "PROOF_TOO_LATE"
            );

            // Strip the 3 least significant bits of the public data hash
            // so we don't have any overflow in the snark field
            publicInputs[i] = uint(specifiedBlock.publicDataHash) >> 3;
            if (i == 0) {
                blockSize = specifiedBlock.blockSize;
                blockType = specifiedBlock.blockType;
                blockVersion = specifiedBlock.blockVersion;
            } else {
                // We only support batch verifying blocks that use the same verifying key
                require(blockType == specifiedBlock.blockType, "INVALID_BATCH_BLOCK_TYPE");
                require(blockSize == specifiedBlock.blockSize, "INVALID_BATCH_BLOCK_SIZE");
                require(blockVersion == specifiedBlock.blockVersion, "INVALID_BATCH_BLOCK_VERSION");
            }
        }

        // Verify the proofs
        require(
            S.blockVerifier.verifyProofs(
                uint8(blockType),
                S.onchainDataAvailability,
                blockSize,
                blockVersion,
                publicInputs,
                proofs
            ),
            "INVALID_PROOF"
        );

        // Mark the blocks as verified
        for (uint i = 0; i < blockIndices.length; i++) {
            uint blockIdx = blockIndices[i];
            ExchangeData.Block storage specifiedBlock = S.blocks[blockIdx];
            // Check this again to make sure no block is verified twice in a single call to verifyBlocks
            require(
                specifiedBlock.state == ExchangeData.BlockState.COMMITTED,
                "BLOCK_VERIFIED_ALREADY"
            );
            specifiedBlock.state = ExchangeData.BlockState.VERIFIED;
            emit BlockVerified(blockIdx);
        }

        // Update the number of blocks that are finalized
        // The number of blocks after the specified block index is limited
        // by MAX_GAP_BETWEEN_FINALIZED_AND_VERIFIED_BLOCKS
        // so we don't have to worry about running out of gas in this loop
        uint idx = S.numBlocksFinalized;
        while (idx < S.blocks.length &&
            S.blocks[idx].state == ExchangeData.BlockState.VERIFIED) {
            emit BlockFinalized(idx);
            idx++;
        }
        S.numBlocksFinalized = idx;
    }

    function revertBlock(
        ExchangeData.State storage S,
        uint blockIdx
        )
        external
    {
        // Exchange cannot be in withdrawal mode
        require(!S.isInWithdrawalMode(), "INVALID_MODE");

        require(blockIdx < S.blocks.length, "INVALID_BLOCK_IDX");
        ExchangeData.Block storage specifiedBlock = S.blocks[blockIdx];
        require(specifiedBlock.state == ExchangeData.BlockState.COMMITTED, "INVALID_BLOCK_STATE");

        // The specified block needs to be the first block not finalized
        // (this way we always revert to a guaranteed valid block and don't revert multiple times)
        require(blockIdx == S.numBlocksFinalized, "PREV_BLOCK_NOT_FINALIZED");

        // Check if this block is verified too late
        require(
            now > specifiedBlock.timestamp + ExchangeData.MAX_PROOF_GENERATION_TIME_IN_SECONDS(),
            "PROOF_NOT_TOO_LATE"
        );

        // Fine the exchange
        uint fine = S.loopring.revertFineLRC();
        S.loopring.burnExchangeStake(S.id, fine);

        // Remove all blocks after and including blockIdx
        S.blocks.length = blockIdx;

        emit Revert(blockIdx);
    }

    // == Internal Functions ==
    function commitBlockInternal(
        ExchangeData.State storage S,
        ExchangeData.BlockType blockType,
        uint16 blockSize,
        uint8  blockVersion,
        bytes  memory data  // This field already has all the dummy (0-valued) requests padded,
                            // therefore the size of this field totally depends on
                            // `blockSize` instead of the actual user requests processed
                            // in this block. This is fine because 0-bytes consume fewer gas.
        )
        private
    {
        // Exchange cannot be in withdrawal mode
        require(!S.isInWithdrawalMode(), "INVALID_MODE");

        // Check if this exchange has a minimal amount of LRC staked
        require(
            S.loopring.canExchangeCommitBlocks(S.id, S.onchainDataAvailability),
            "INSUFFICIENT_EXCHANGE_STAKE"
        );

        // Check if the block is supported
        require(
            S.blockVerifier.isCircuitEnabled(
                uint8(blockType),
                S.onchainDataAvailability,
                blockSize,
                blockVersion
            ),
            "CANNOT_VERIFY_BLOCK"
        );

        // Extract the exchange ID from the data
        uint32 exchangeIdInData = 0;
        assembly {
            exchangeIdInData := and(mload(add(data, 4)), 0xFFFFFFFF)
        }
        require(exchangeIdInData == S.id, "INVALID_EXCHANGE_ID");

        // Get the current block
        ExchangeData.Block storage prevBlock = S.blocks[S.blocks.length - 1];

        // Get the old and new Merkle roots
        bytes32 merkleRootBefore;
        bytes32 merkleRootAfter;
        assembly {
            merkleRootBefore := mload(add(data, 36))
            merkleRootAfter := mload(add(data, 68))
        }
        require(merkleRootBefore == prevBlock.merkleRoot, "INVALID_MERKLE_ROOT");

        uint32 numDepositRequestsCommitted = uint32(prevBlock.numDepositRequestsCommitted);
        uint32 numWithdrawalRequestsCommitted = uint32(prevBlock.numWithdrawalRequestsCommitted);

        // When the exchange is shutdown:
        // - First force all outstanding deposits to be done
        // - Allow withdrawing using the special shutdown mode of ONCHAIN_WITHDRAWAL (with
        //   count == 0)
        if (S.isShutdown()) {
            if (numDepositRequestsCommitted < S.depositChain.length) {
                require(blockType == ExchangeData.BlockType.DEPOSIT, "SHUTDOWN_DEPOSIT_BLOCK_FORCED");
            } else {
                require(blockType == ExchangeData.BlockType.ONCHAIN_WITHDRAWAL, "SHUTDOWN_WITHDRAWAL_BLOCK_FORCED");
            }
        }

        // Check if the operator is forced to commit a deposit or withdraw block
        // We give priority to withdrawals. If a withdraw block is forced it needs to
        // be processed first, even if there is also a deposit block forced.
        if (isWithdrawalRequestForced(S, numWithdrawalRequestsCommitted)) {
            require(blockType == ExchangeData.BlockType.ONCHAIN_WITHDRAWAL, "WITHDRAWAL_BLOCK_FORCED");
        } else if (isDepositRequestForced(S, numDepositRequestsCommitted)) {
            require(blockType == ExchangeData.BlockType.DEPOSIT, "DEPOSIT_BLOCK_FORCED");
        }

        if (blockType == ExchangeData.BlockType.RING_SETTLEMENT) {
            require(S.areUserRequestsEnabled(), "SETTLEMENT_SUSPENDED");
            uint32 inputTimestamp;
            uint8 protocolTakerFeeBips;
            uint8 protocolMakerFeeBips;
            assembly {
                inputTimestamp := and(mload(add(data, 72)), 0xFFFFFFFF)
                protocolTakerFeeBips := and(mload(add(data, 73)), 0xFF)
                protocolMakerFeeBips := and(mload(add(data, 74)), 0xFF)
            }
            require(
                inputTimestamp > now - ExchangeData.TIMESTAMP_HALF_WINDOW_SIZE_IN_SECONDS() &&
                inputTimestamp < now + ExchangeData.TIMESTAMP_HALF_WINDOW_SIZE_IN_SECONDS(),
                "INVALID_TIMESTAMP"
            );
            require(
                validateAndUpdateProtocolFeeValues(S, protocolTakerFeeBips, protocolMakerFeeBips),
                "INVALID_PROTOCOL_FEES"
            );
        } else if (blockType == ExchangeData.BlockType.DEPOSIT) {
            uint startIdx = 0;
            uint count = 0;
            assembly {
                startIdx := and(mload(add(data, 136)), 0xFFFFFFFF)
                count := and(mload(add(data, 140)), 0xFFFFFFFF)
            }
            require (startIdx == numDepositRequestsCommitted, "INVALID_REQUEST_RANGE");
            require (count <= blockSize, "INVALID_REQUEST_RANGE");
            require (startIdx + count <= S.depositChain.length, "INVALID_REQUEST_RANGE");

            bytes32 startingHash = S.depositChain[startIdx - 1].accumulatedHash;
            bytes32 endingHash = S.depositChain[startIdx + count - 1].accumulatedHash;
            // Pad the block so it's full
            for (uint i = count; i < blockSize; i++) {
                endingHash = sha256(
                    abi.encodePacked(
                        endingHash,
                        uint24(0),
                        uint(0),
                        uint(0),
                        uint8(0),
                        uint96(0)
                    )
                );
            }
            bytes32 inputStartingHash = 0x0;
            bytes32 inputEndingHash = 0x0;
            assembly {
                inputStartingHash := mload(add(data, 100))
                inputEndingHash := mload(add(data, 132))
            }
            require(inputStartingHash == startingHash, "INVALID_STARTING_HASH");
            require(inputEndingHash == endingHash, "INVALID_ENDING_HASH");

            numDepositRequestsCommitted += uint32(count);
        } else if (blockType == ExchangeData.BlockType.ONCHAIN_WITHDRAWAL) {
            uint startIdx = 0;
            uint count = 0;
            assembly {
                startIdx := and(mload(add(data, 136)), 0xFFFFFFFF)
                count := and(mload(add(data, 140)), 0xFFFFFFFF)
            }
            require (startIdx == numWithdrawalRequestsCommitted, "INVALID_REQUEST_RANGE");
            require (count <= blockSize, "INVALID_REQUEST_RANGE");
            require (startIdx + count <= S.withdrawalChain.length, "INVALID_REQUEST_RANGE");

            if (S.isShutdown()) {
                require (count == 0, "INVALID_WITHDRAWAL_COUNT");
                // Don't check anything here, the operator can do all necessary withdrawals
                // in any order he wants (the circuit still ensures the withdrawals are valid)
            } else {
                require (count > 0, "INVALID_WITHDRAWAL_COUNT");
                bytes32 startingHash = S.withdrawalChain[startIdx - 1].accumulatedHash;
                bytes32 endingHash = S.withdrawalChain[startIdx + count - 1].accumulatedHash;
                // Pad the block so it's full
                for (uint i = count; i < blockSize; i++) {
                    endingHash = sha256(
                        abi.encodePacked(
                            endingHash,
                            uint24(0),
                            uint8(0),
                            uint96(0)
                        )
                    );
                }
                bytes32 inputStartingHash = 0x0;
                bytes32 inputEndingHash = 0x0;
                assembly {
                    inputStartingHash := mload(add(data, 100))
                    inputEndingHash := mload(add(data, 132))
                }
                require(inputStartingHash == startingHash, "INVALID_STARTING_HASH");
                require(inputEndingHash == endingHash, "INVALID_ENDING_HASH");
                numWithdrawalRequestsCommitted += uint32(count);
            }
        } else if (
            blockType != ExchangeData.BlockType.OFFCHAIN_WITHDRAWAL &&
            blockType != ExchangeData.BlockType.ORDER_CANCELLATION &&
            blockType != ExchangeData.BlockType.TRANSFER) {
            revert("UNSUPPORTED_BLOCK_TYPE");
        }

        // Hash all the public data to a single value which is used as the input for the circuit
        bytes32 publicDataHash = data.fastSHA256();

        // Store the approved withdrawal data onchain
        bytes memory withdrawals = new bytes(0);
        if (blockType == ExchangeData.BlockType.ONCHAIN_WITHDRAWAL ||
            blockType == ExchangeData.BlockType.OFFCHAIN_WITHDRAWAL) {
            uint start = 4 + 32 + 32;
            if (blockType == ExchangeData.BlockType.ONCHAIN_WITHDRAWAL) {
                start += 32 + 32 + 4 + 4;
            }
            uint length = 7 * blockSize;
            assembly {
                withdrawals := add(data, start)
                mstore(withdrawals, length)
            }
        }

        // Create a new block with the updated merkle roots
        ExchangeData.Block memory newBlock = ExchangeData.Block(
            merkleRootAfter,
            publicDataHash,
            ExchangeData.BlockState.COMMITTED,
            blockType,
            blockSize,
            blockVersion,
            uint32(now),
            numDepositRequestsCommitted,
            numWithdrawalRequestsCommitted,
            false,
            0,
            withdrawals
        );

        S.blocks.push(newBlock);

        emit BlockCommitted(S.blocks.length - 1, publicDataHash);
    }

    function validateAndUpdateProtocolFeeValues(
        ExchangeData.State storage S,
        uint8 takerFeeBips,
        uint8 makerFeeBips
        )
        private
        returns (bool)
    {
        ExchangeData.ProtocolFeeData storage data = S.protocolFeeData;
        if (now > data.timestamp + ExchangeData.MIN_AGE_PROTOCOL_FEES_UNTIL_UPDATED()) {
            // Store the current protocol fees in the previous protocol fees
            data.previousTakerFeeBips = data.takerFeeBips;
            data.previousMakerFeeBips = data.makerFeeBips;
            // Get the latest protocol fees for this exchange
            (data.takerFeeBips, data.makerFeeBips) = S.loopring.getProtocolFeeValues(
                S.id,
                S.onchainDataAvailability
            );
            data.timestamp = uint32(now);

            bool feeUpdated = (data.takerFeeBips != data.previousTakerFeeBips) ||
                (data.makerFeeBips != data.previousMakerFeeBips);

            if (feeUpdated) {
                emit ProtocolFeesUpdated(
                    data.takerFeeBips,
                    data.makerFeeBips,
                    data.previousTakerFeeBips,
                    data.previousMakerFeeBips
                );
            }
        }
        // The given fee values are valid if they are the current or previous protocol fee values
        return (takerFeeBips == data.takerFeeBips && makerFeeBips == data.makerFeeBips) ||
            (takerFeeBips == data.previousTakerFeeBips && makerFeeBips == data.previousMakerFeeBips);
    }

    function isDepositRequestForced(
        ExchangeData.State storage S,
        uint numRequestsCommitted
        )
        private
        view
        returns (bool)
    {
        if (numRequestsCommitted == S.depositChain.length) {
            return false;
        } else {
            return S.depositChain[numRequestsCommitted].timestamp < now.sub(
                ExchangeData.MAX_AGE_REQUEST_UNTIL_FORCED());
        }
    }

    function isWithdrawalRequestForced(
        ExchangeData.State storage S,
        uint numRequestsCommitted
        )
        private
        view
        returns (bool)
    {
        if (numRequestsCommitted == S.withdrawalChain.length) {
            return false;
        } else {
            return S.withdrawalChain[numRequestsCommitted].timestamp < now.sub(
                ExchangeData.MAX_AGE_REQUEST_UNTIL_FORCED());
        }
    }
}
