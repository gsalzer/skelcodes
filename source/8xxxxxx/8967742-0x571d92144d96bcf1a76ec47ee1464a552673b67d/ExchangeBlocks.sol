/**
Author: Loopring Foundation (Loopring Project Ltd)
*/

pragma solidity ^0.5.11;


library BytesUtil {
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

library MathUint {
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

contract IBlockVerifier {
    

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

    

    
    
    
    
    
    
    
    
    
    
    function registerCircuit(
        uint8    blockType,
        bool     onchainDataAvailability,
        uint16   blockSize,
        uint8    blockVersion,
        uint[18] calldata vk
        )
        external;

    
    
    
    
    
    
    
    
    function disableCircuit(
        uint8  blockType,
        bool   onchainDataAvailability,
        uint16 blockSize,
        uint8  blockVersion
        )
        external;

    
    
    
    
    
    
    
    
    
    
    
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

    
    
    
    
    
    
    
    function isCircuitRegistered(
        uint8  blockType,
        bool   onchainDataAvailability,
        uint16 blockSize,
        uint8  blockVersion
        )
        external
        view
        returns (bool);

    
    
    
    
    
    
    
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

contract IDecompressor {
    
    
    
    function decompress(
        bytes calldata data
        )
        external
        pure
        returns (bytes memory decompressedData);
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    
    
    constructor()
        public
    {
        owner = msg.sender;
    }

    
    modifier onlyOwner()
    {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    
    
    
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

contract Claimable is Ownable
{
    address public pendingOwner;

    
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "UNAUTHORIZED");
        _;
    }

    
    
    function transferOwnership(
        address newOwner
        )
        public
        onlyOwner
    {
        require(newOwner != address(0) && newOwner != owner, "INVALID_ADDRESS");
        pendingOwner = newOwner;
    }

    
    function claimOwnership()
        public
        onlyPendingOwner
    {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

contract ReentrancyGuard {
    
    uint private _guardValue;

    
    modifier nonReentrant()
    {
        
        require(_guardValue == 0, "REENTRANCY");

        
        _guardValue = 1;

        
        _;

        
        _guardValue = 0;
    }
}

contract ILoopring is Claimable, ReentrancyGuard
{
    string  constant public version = ""; 

    uint    public exchangeCreationCostLRC;
    address public universalRegistry;
    address public lrcAddress;

    event ExchangeInitialized(
        uint    indexed exchangeId,
        address indexed exchangeAddress,
        address indexed owner,
        address         operator,
        bool            onchainDataAvailability
    );

    
    
    
    
    
    
    
    
    
    
    function initializeExchange(
        address exchangeAddress,
        uint    exchangeId,
        address owner,
        address payable operator,
        bool    onchainDataAvailability
        )
        external;
}

contract ILoopringV3 is ILoopring
{
    

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

    
    struct Exchange
    {
        address exchangeAddress;
        uint    exchangeStake;
        uint    protocolFeeStake;
    }

    mapping (uint => Exchange) internal exchanges;

    string  constant public version = "3.0";

    address public wethAddress;
    uint    public totalStake;
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

    
    
    
    
    
    
    function updateSettings(
        address payable _protocolFeeVault,   
        address _blockVerifierAddress,       
        address _downtimeCostCalculator,     
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

    
    
    
    
    
    function updateProtocolFeeSettings(
        uint8 _minProtocolTakerFeeBips,
        uint8 _maxProtocolTakerFeeBips,
        uint8 _minProtocolMakerFeeBips,
        uint8 _maxProtocolMakerFeeBips,
        uint  _targetProtocolTakerFeeStake,
        uint  _targetProtocolMakerFeeStake
        )
        external;

    
    
    
    
    
    
    
    
    
    function canExchangeCommitBlocks(
        uint exchangeId,
        bool onchainDataAvailability
        )
        external
        view
        returns (bool);

    
    
    
    function getExchangeStake(
        uint exchangeId
        )
        public
        view
        returns (uint stakedLRC);

    
    
    
    
    
    function burnExchangeStake(
        uint exchangeId,
        uint amount
        )
        external
        returns (uint burnedLRC);

    
    
    
    
    function depositExchangeStake(
        uint exchangeId,
        uint amountLRC
        )
        external
        returns (uint stakedLRC);

    
    
    
    
    
    
    function withdrawExchangeStake(
        uint    exchangeId,
        address recipient,
        uint    requestedAmount
        )
        external
        returns (uint amount);

    
    
    
    
    function depositProtocolFeeStake(
        uint exchangeId,
        uint amountLRC
        )
        external
        returns (uint stakedLRC);

    
    
    
    
    
    function withdrawProtocolFeeStake(
        uint    exchangeId,
        address recipient,
        uint    amount
        )
        external;

    
    
    
    
    
    
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

    
    
    
    function getProtocolFeeStake(
        uint exchangeId
        )
        external
        view
        returns (uint protocolFeeStake);
}

library ExchangeData {
    
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
        
        
        NEW,            

        
        COMMITTED,      

        
        
        VERIFIED        
    }

    
    struct Account
    {
        address owner;

        
        
        
        
        
        
        
        
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

    
    
    struct Block
    {
        
        
        bytes32 merkleRoot;

        
        
        
        
        
        
        bytes32 publicDataHash;

        
        BlockState state;

        
        
        BlockType blockType;

        
        
        
        
        uint16 blockSize;

        
        uint8  blockVersion;

        
        uint32 timestamp;

        
        
        uint32 numDepositRequestsCommitted;

        
        
        uint32 numWithdrawalRequestsCommitted;

        
        
        bool   blockFeeWithdrawn;

        
        uint16 numWithdrawalsDistributed;

        
        
        
        
        
        
        
        
        bytes  withdrawals;
    }

    
    
    
    struct Request
    {
        bytes32 accumulatedHash;
        uint    accumulatedFee;
        uint32  timestamp;
    }

    
    struct Deposit
    {
        uint24 accountID;
        uint16 tokenID;
        uint96 amount;
    }

    function SNARK_SCALAR_FIELD() internal pure returns (uint) {
        
        return 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    }

    function MAX_PROOF_GENERATION_TIME_IN_SECONDS() internal pure returns (uint32) { return 14 days; }
    function MAX_GAP_BETWEEN_FINALIZED_AND_VERIFIED_BLOCKS() internal pure returns (uint32) { return 1000; }
    function MAX_OPEN_DEPOSIT_REQUESTS() internal pure returns (uint16) { return 1024; }
    function MAX_OPEN_WITHDRAWAL_REQUESTS() internal pure returns (uint16) { return 1024; }
    function MAX_AGE_UNFINALIZED_BLOCK_UNTIL_WITHDRAW_MODE() internal pure returns (uint32) { return 21 days; }
    function MAX_AGE_REQUEST_UNTIL_FORCED() internal pure returns (uint32) { return 14 days; }
    function MAX_AGE_REQUEST_UNTIL_WITHDRAW_MODE() internal pure returns (uint32) { return 15 days; }
    function MAX_TIME_IN_SHUTDOWN_BASE() internal pure returns (uint32) { return 30 days; }
    function MAX_TIME_IN_SHUTDOWN_DELTA() internal pure returns (uint32) { return 1 seconds; }
    function TIMESTAMP_HALF_WINDOW_SIZE_IN_SECONDS() internal pure returns (uint32) { return 7 days; }
    function MAX_NUM_TOKENS() internal pure returns (uint) { return 2 ** 8; }
    function MAX_NUM_ACCOUNTS() internal pure returns (uint) { return 2 ** 20 - 1; }
    function MAX_TIME_TO_DISTRIBUTE_WITHDRAWALS() internal pure returns (uint32) { return 14 days; }
    function MAX_TIME_TO_DISTRIBUTE_WITHDRAWALS_SHUTDOWN_MODE() internal pure returns (uint32) {
        return MAX_TIME_TO_DISTRIBUTE_WITHDRAWALS() * 10;
    }
    function FEE_BLOCK_FINE_START_TIME() internal pure returns (uint32) { return 6 hours; }
    function FEE_BLOCK_FINE_MAX_DURATION() internal pure returns (uint32) { return 6 hours; }
    function MIN_GAS_TO_DISTRIBUTE_WITHDRAWALS() internal pure returns (uint32) { return 150000; }
    function MIN_AGE_PROTOCOL_FEES_UNTIL_UPDATED() internal pure returns (uint32) { return 1 days; }
    function GAS_LIMIT_SEND_TOKENS() internal pure returns (uint32) { return 60000; }

    
    struct State
    {
        uint    id;
        uint    exchangeCreationTimestamp;
        address payable operator; 
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

        
        mapping (address => uint24) ownerToAccountId;
        mapping (address => uint16) tokenToTokenId;

        
        mapping (address => mapping (address => bool)) withdrawnInWithdrawMode;

        
        mapping (address => uint) tokenBalances;

        
        
        
        uint numBlocksFinalized;

        
        ProtocolFeeData protocolFeeData;

        
        uint shutdownStartTime;
    }
}

library ExchangeMode {
    using MathUint  for uint;

    function isInWithdrawalMode(
        ExchangeData.State storage S
        )
        internal 
        view
        returns (bool result)
    {
        result = false;
        ExchangeData.Block storage currentBlock = S.blocks[S.blocks.length - 1];

        
        if (currentBlock.numDepositRequestsCommitted < S.depositChain.length) {
            uint32 requestTimestamp = S.depositChain[currentBlock.numDepositRequestsCommitted].timestamp;
            result = requestTimestamp < now.sub(ExchangeData.MAX_AGE_REQUEST_UNTIL_WITHDRAW_MODE());
        }

        
        if (result == false && currentBlock.numWithdrawalRequestsCommitted < S.withdrawalChain.length) {
            uint32 requestTimestamp = S.withdrawalChain[currentBlock.numWithdrawalRequestsCommitted].timestamp;
            result = requestTimestamp < now.sub(ExchangeData.MAX_AGE_REQUEST_UNTIL_WITHDRAW_MODE());
        }

        
        if (result == false) {
            result = isAnyUnfinalizedBlockTooOld(S);
        }

        
        if (result == false && isShutdown(S) && !isInInitialState(S)) {
            
            
            uint maxTimeInShutdown = ExchangeData.MAX_TIME_IN_SHUTDOWN_BASE();
            maxTimeInShutdown = maxTimeInShutdown.add(S.accounts.length.mul(ExchangeData.MAX_TIME_IN_SHUTDOWN_DELTA()));
            result = now > S.shutdownStartTime.add(maxTimeInShutdown);
        }
    }

    function isShutdown(
        ExchangeData.State storage S
        )
        internal 
        view
        returns (bool)
    {
        return S.shutdownStartTime > 0;
    }

    function isInMaintenance(
        ExchangeData.State storage S
        )
        internal 
        view
        returns (bool)
    {
        return S.downtimeStart != 0 && getNumDowntimeMinutesLeft(S) > 0;
    }

    function isInInitialState(
        ExchangeData.State storage S
        )
        internal 
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
        internal 
        view
        returns (bool)
    {
        
        
        return !isInMaintenance(S) && !isShutdown(S) && !isInWithdrawalMode(S);
    }

    function isAnyUnfinalizedBlockTooOld(
        ExchangeData.State storage S
        )
        internal 
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
        internal 
        view
        returns (uint)
    {
        if (S.downtimeStart == 0) {
            return S.numDowntimeMinutes;
        } else {
            
            uint numDowntimeMinutesUsed = now.sub(S.downtimeStart) / 60;
            if (S.numDowntimeMinutes > numDowntimeMinutesUsed) {
                return S.numDowntimeMinutes.sub(numDowntimeMinutesUsed);
            } else {
                return 0;
            }
        }
    }
}

library ExchangeBlocks {
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
        bytes  calldata 
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
        
        require(!S.isInWithdrawalMode(), "INVALID_MODE");

        
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

            
            
            
            require(
                blockIdx < S.numBlocksFinalized + ExchangeData.MAX_GAP_BETWEEN_FINALIZED_AND_VERIFIED_BLOCKS(),
                "PROOF_TOO_EARLY"
            );

            
            require(
                now <= specifiedBlock.timestamp + ExchangeData.MAX_PROOF_GENERATION_TIME_IN_SECONDS(),
                "PROOF_TOO_LATE"
            );

            
            
            publicInputs[i] = uint(specifiedBlock.publicDataHash) >> 3;
            if (i == 0) {
                blockSize = specifiedBlock.blockSize;
                blockType = specifiedBlock.blockType;
                blockVersion = specifiedBlock.blockVersion;
            } else {
                
                require(blockType == specifiedBlock.blockType, "INVALID_BATCH_BLOCK_TYPE");
                require(blockSize == specifiedBlock.blockSize, "INVALID_BATCH_BLOCK_SIZE");
                require(blockVersion == specifiedBlock.blockVersion, "INVALID_BATCH_BLOCK_VERSION");
            }
        }

        
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

        
        for (uint i = 0; i < blockIndices.length; i++) {
            uint blockIdx = blockIndices[i];
            ExchangeData.Block storage specifiedBlock = S.blocks[blockIdx];
            
            require(
                specifiedBlock.state == ExchangeData.BlockState.COMMITTED,
                "BLOCK_VERIFIED_ALREADY"
            );
            specifiedBlock.state = ExchangeData.BlockState.VERIFIED;
            emit BlockVerified(blockIdx);
        }

        
        
        
        
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
        
        require(!S.isInWithdrawalMode(), "INVALID_MODE");

        require(blockIdx < S.blocks.length, "INVALID_BLOCK_IDX");
        ExchangeData.Block storage specifiedBlock = S.blocks[blockIdx];
        require(specifiedBlock.state == ExchangeData.BlockState.COMMITTED, "INVALID_BLOCK_STATE");

        
        require(blockIdx >= S.numBlocksFinalized, "FINALIZED_BLOCK_REVERT_PROHIBITED");

        
        uint fine = S.loopring.revertFineLRC();
        S.loopring.burnExchangeStake(S.id, fine);

        
        S.blocks.length = blockIdx;

        emit Revert(blockIdx);
    }

    
    function commitBlockInternal(
        ExchangeData.State storage S,
        ExchangeData.BlockType blockType,
        uint16 blockSize,
        uint8  blockVersion,
        bytes  memory data  
                            
                            
                            
        )
        private
    {
        
        require(!S.isInWithdrawalMode(), "INVALID_MODE");

        
        require(
            S.loopring.canExchangeCommitBlocks(S.id, S.onchainDataAvailability),
            "INSUFFICIENT_EXCHANGE_STAKE"
        );

        
        require(
            S.blockVerifier.isCircuitEnabled(
                uint8(blockType),
                S.onchainDataAvailability,
                blockSize,
                blockVersion
            ),
            "CANNOT_VERIFY_BLOCK"
        );

        
        uint32 exchangeIdInData = 0;
        assembly {
            exchangeIdInData := and(mload(add(data, 4)), 0xFFFFFFFF)
        }
        require(exchangeIdInData == S.id, "INVALID_EXCHANGE_ID");

        
        ExchangeData.Block storage prevBlock = S.blocks[S.blocks.length - 1];

        
        bytes32 merkleRootBefore;
        bytes32 merkleRootAfter;
        assembly {
            merkleRootBefore := mload(add(data, 36))
            merkleRootAfter := mload(add(data, 68))
        }
        require(merkleRootBefore == prevBlock.merkleRoot, "INVALID_MERKLE_ROOT");
        require(uint256(merkleRootAfter) < ExchangeData.SNARK_SCALAR_FIELD(), "INVALID_MERKLE_ROOT");

        uint32 numDepositRequestsCommitted = uint32(prevBlock.numDepositRequestsCommitted);
        uint32 numWithdrawalRequestsCommitted = uint32(prevBlock.numWithdrawalRequestsCommitted);

        
        
        
        
        if (S.isShutdown()) {
            if (numDepositRequestsCommitted < S.depositChain.length) {
                require(blockType == ExchangeData.BlockType.DEPOSIT, "SHUTDOWN_DEPOSIT_BLOCK_FORCED");
            } else {
                require(blockType == ExchangeData.BlockType.ONCHAIN_WITHDRAWAL, "SHUTDOWN_WITHDRAWAL_BLOCK_FORCED");
            }
        }

        
        
        
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
                
                
            } else {
                require (count > 0, "INVALID_WITHDRAWAL_COUNT");
                bytes32 startingHash = S.withdrawalChain[startIdx - 1].accumulatedHash;
                bytes32 endingHash = S.withdrawalChain[startIdx + count - 1].accumulatedHash;
                
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

        
        bytes32 publicDataHash = data.fastSHA256();

        
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
            
            data.previousTakerFeeBips = data.takerFeeBips;
            data.previousMakerFeeBips = data.makerFeeBips;
            
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
