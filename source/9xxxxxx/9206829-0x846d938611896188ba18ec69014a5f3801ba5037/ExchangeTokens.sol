/**
Author: Loopring Foundation (Loopring Project Ltd)
*/

pragma solidity ^0.5.11;


contract ERC20 {
    function totalSupply()
        public
        view
        returns (uint);

    function balanceOf(
        address who
        )
        public
        view
        returns (uint);

    function allowance(
        address owner,
        address spender
        )
        public
        view
        returns (uint);

    function transfer(
        address to,
        uint value
        )
        public
        returns (bool);

    function transferFrom(
        address from,
        address to,
        uint    value
        )
        public
        returns (bool);

    function approve(
        address spender,
        uint    value
        )
        public
        returns (bool);
}

contract BurnableERC20 is ERC20
{
    function burn(
        uint value
        )
        public
        returns (bool);

    function burnFrom(
        address from,
        uint value
        )
        public
        returns (bool);
}

library ERC20SafeTransfer {
    function safeTransferAndVerify(
        address token,
        address to,
        uint    value
        )
        internal
    {
        safeTransferWithGasLimitAndVerify(
            token,
            to,
            value,
            gasleft()
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint    value
        )
        internal
        returns (bool)
    {
        return safeTransferWithGasLimit(
            token,
            to,
            value,
            gasleft()
        );
    }

    function safeTransferWithGasLimitAndVerify(
        address token,
        address to,
        uint    value,
        uint    gasLimit
        )
        internal
    {
        require(
            safeTransferWithGasLimit(token, to, value, gasLimit),
            "TRANSFER_FAILURE"
        );
    }

    function safeTransferWithGasLimit(
        address token,
        address to,
        uint    value,
        uint    gasLimit
        )
        internal
        returns (bool)
    {
        
        
        

        
        bytes memory callData = abi.encodeWithSelector(
            bytes4(0xa9059cbb),
            to,
            value
        );
        (bool success, ) = token.call.gas(gasLimit)(callData);
        return checkReturnValue(success);
    }

    function safeTransferFromAndVerify(
        address token,
        address from,
        address to,
        uint    value
        )
        internal
    {
        safeTransferFromWithGasLimitAndVerify(
            token,
            from,
            to,
            value,
            gasleft()
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint    value
        )
        internal
        returns (bool)
    {
        return safeTransferFromWithGasLimit(
            token,
            from,
            to,
            value,
            gasleft()
        );
    }

    function safeTransferFromWithGasLimitAndVerify(
        address token,
        address from,
        address to,
        uint    value,
        uint    gasLimit
        )
        internal
    {
        bool result = safeTransferFromWithGasLimit(
            token,
            from,
            to,
            value,
            gasLimit
        );
        require(result, "TRANSFER_FAILURE");
    }

    function safeTransferFromWithGasLimit(
        address token,
        address from,
        address to,
        uint    value,
        uint    gasLimit
        )
        internal
        returns (bool)
    {
        
        
        

        
        bytes memory callData = abi.encodeWithSelector(
            bytes4(0x23b872dd),
            from,
            to,
            value
        );
        (bool success, ) = token.call.gas(gasLimit)(callData);
        return checkReturnValue(success);
    }

    function checkReturnValue(
        bool success
        )
        internal
        pure
        returns (bool)
    {
        
        
        
        if (success) {
            assembly {
                switch returndatasize()
                
                case 0 {
                    success := 1
                }
                
                case 32 {
                    returndatacopy(0, 0, 32)
                    success := mload(0)
                }
                
                default {
                    success := 0
                }
            }
        }
        return success;
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

contract IBlockVerifier is Claimable
{
    

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

    string  constant public version = "3.1";

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

library ExchangeTokens {
    using MathUint          for uint;
    using ERC20SafeTransfer for address;
    using ExchangeMode      for ExchangeData.State;

    event TokenRegistered(
        address indexed token,
        uint16  indexed tokenId
    );

    function registerToken(
        ExchangeData.State storage S,
        address tokenAddress
        )
        external
        returns (uint16 tokenID)
    {
        tokenID = registerToken(
            S,
            tokenAddress,
            getLRCFeeForRegisteringOneMoreToken(S)
        );
    }

    function getTokenAddress(
        ExchangeData.State storage S,
        uint16 tokenID
        )
        external
        view
        returns (address)
    {
        require(tokenID < S.tokens.length, "INVALID_TOKEN_ID");
        return S.tokens[tokenID].token;
    }

    function getLRCFeeForRegisteringOneMoreToken(
        ExchangeData.State storage S
        )
        public
        view
        returns (uint feeLRC)
    {
        return S.loopring.tokenRegistrationFeeLRCBase().add(
            S.loopring.tokenRegistrationFeeLRCDelta().mul(S.tokens.length)
        );
    }

    function registerToken(
        ExchangeData.State storage S,
        address tokenAddress,
        uint    amountToBurn
        )
        public
        returns (uint16 tokenID)
    {
        require(!S.isInWithdrawalMode(), "INVALID_MODE");
        require(S.tokenToTokenId[tokenAddress] == 0, "TOKEN_ALREADY_EXIST");
        require(S.tokens.length < ExchangeData.MAX_NUM_TOKENS(), "TOKEN_REGISTRY_FULL");

        if (amountToBurn > 0) {
            address feeVault = S.loopring.protocolFeeVault();
            S.lrcAddress.safeTransferFromAndVerify(msg.sender, feeVault, amountToBurn);
        }

        ExchangeData.Token memory token = ExchangeData.Token(tokenAddress, false);
        S.tokens.push(token);
        tokenID = uint16(S.tokens.length - 1);
        S.tokenToTokenId[tokenAddress] = tokenID + 1;

        emit TokenRegistered(tokenAddress, tokenID);
    }

    function getTokenID(
        ExchangeData.State storage S,
        address tokenAddress
        )
        public
        view
        returns (uint16 tokenID)
    {
        tokenID = S.tokenToTokenId[tokenAddress];
        require(tokenID != 0, "TOKEN_NOT_FOUND");
        tokenID = tokenID - 1;
    }

    function disableTokenDeposit(
        ExchangeData.State storage S,
        address tokenAddress
        )
        external
    {
        require(!S.isInWithdrawalMode(), "INVALID_MODE");

        require(tokenAddress != address(0), "ETHER_CANNOT_BE_DISABLED");
        require(tokenAddress != S.loopring.wethAddress(), "WETH_CANNOT_BE_DISABLED");
        require(tokenAddress != S.loopring.lrcAddress(), "LRC_CANNOT_BE_DISABLED");

        uint16 tokenID = getTokenID(S, tokenAddress);
        ExchangeData.Token storage token = S.tokens[tokenID];
        require(!token.depositDisabled, "TOKEN_DEPOSIT_ALREADY_DISABLED");
        token.depositDisabled = true;
    }

    function enableTokenDeposit(
        ExchangeData.State storage S,
        address tokenAddress
        )
        external
    {
        require(!S.isInWithdrawalMode(), "INVALID_MODE");
        uint16 tokenID = getTokenID(S, tokenAddress);
        ExchangeData.Token storage token = S.tokens[tokenID];
        require(token.depositDisabled, "TOKEN_DEPOSIT_ALREADY_ENABLED");
        token.depositDisabled = false;
    }
}
