// File: @openzeppelin/contracts/GSN/Context.sol


pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity ^0.6.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol


pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @api3-contracts/api3-token/contracts/interfaces/IApi3Token.sol

pragma solidity 0.6.12;



interface IApi3Token is IERC20 {
    event MinterStatusUpdated(
        address indexed minterAddress,
        bool minterStatus
        );

    event BurnerStatusUpdated(
        address indexed burnerAddress,
        bool burnerStatus
        );

    function updateMinterStatus(
        address minterAddress,
        bool minterStatus
        )
        external;

    function updateBurnerStatus(bool burnerStatus)
        external;

    function mint(
        address account,
        uint256 amount
        )
        external;

    function burn(uint256 amount)
        external;

    function getMinterStatus(address minterAddress)
        external
        view
        returns(bool minterStatus);

    function getBurnerStatus(address burnerAddress)
        external
        view
        returns(bool burnerStatus);
}

// File: @api3-contracts/api3-pool/contracts/interfaces/IApi3State.sol

pragma solidity 0.6.12;



interface IApi3State {
    enum ClaimStatus { Pending, Accepted, Denied }

    event InflationManagerUpdated(address inflationManagerAddress);
    event ClaimsManagerUpdated(address claimsManagerAddress);
    event RewardVestingPeriodUpdated(uint256 rewardVestingPeriod);
    event UnpoolRequestCooldownUpdated(uint256 unpoolRequestCooldown);
    event UnpoolWaitingPeriodUpdated(uint256 unpoolWaitingPeriod);

    function updateInflationManager(address inflationManagerAddress)
        external;

    function updateClaimsManager(address claimsManagerAddress)
        external;

    function updateRewardVestingPeriod(uint256 _rewardVestingPeriod)
        external;

    function updateUnpoolRequestCooldown(uint256 _unpoolRequestCooldown)
        external;

    function updateUnpoolWaitingPeriod(uint256 _unpoolWaitingPeriod)
        external;
}

// File: @api3-contracts/api3-pool/contracts/interfaces/IEpochUtils.sol

pragma solidity 0.6.12;



interface IEpochUtils is IApi3State {
    function getCurrentEpochIndex()
        external
        view
        returns(uint256 currentEpochIndex);

    function getEpochIndex(uint256 timestamp)
        external
        view
        returns(uint256 epochIndex);
}

// File: @api3-contracts/api3-pool/contracts/interfaces/IGetterUtils.sol

pragma solidity 0.6.12;



interface IGetterUtils is IEpochUtils {
    function getPooled(address userAddress)
        external
        view
        returns(uint256 pooled);

    function getVotingPower(
        address delegate,
        uint256 timestamp
        )
        external
        view
        returns(uint256 votingPower);

    function getTotalRealPooled()
        external
        view
        returns(uint256 totalRealPooled);

    function getBalance(address userAddress)
        external
        view
        returns(uint256 balance);

    function getShare(address userAddress)
        external
        view
        returns(uint256 share);

    function getUnpoolRequestEpoch(address userAddress)
        external
        view
        returns(uint256 unpoolRequestEpoch);

    function getTotalStaked(uint256 epochIndex)
        external
        view
        returns(uint256 totalStaked);

    function getStaked(
        address userAddress,
        uint256 epochIndex
        )
        external
        view
        returns(uint256 staked);

    function getDelegate(address userAddress)
        external
        view
        returns(address delegate);

    function getDelegated(
        address delegate,
        uint256 epochIndex
        )
        external
        view
        returns(uint256 delegated);

    function getVestedRewards(uint256 epochIndex)
        external
        view
        returns(uint256 vestedRewards);

    function getUnpaidVestedRewards(uint256 epochIndex)
        external
        view
        returns(uint256 unpaidVestedRewards);

    function getInstantRewards(uint256 epochIndex)
        external
        view
        returns(uint256 instantRewards);

    function getUnpaidInstantRewards(uint256 epochIndex)
        external
        view
        returns(uint256 unpaidInstantRewards);

    function getVesting(bytes32 vestingId)
        external
        view
        returns(
            address userAddress,
            uint256 amount,
            uint256 epoch
            );

    function getUnvestedFund(address userAddress)
        external
        view
        returns(uint256 unvestedFund);

    function getClaim(bytes32 claimId)
        external
        view
        returns(
            address beneficiary,
            uint256 amount,
            IApi3State.ClaimStatus status
            );

    function getActiveClaims()
        external
        view
        returns(bytes32[] memory _activeClaims);

    function getIou(bytes32 iouId)
        external
        view
        returns(
            address userAddress,
            uint256 amountInShares,
            bytes32 claimId,
            IApi3State.ClaimStatus redemptionCondition
            );
}

// File: @api3-contracts/api3-pool/contracts/interfaces/IClaimUtils.sol

pragma solidity 0.6.12;



interface IClaimUtils is IGetterUtils {
    event ClaimCreated(
        bytes32 indexed claimId,
        address indexed beneficiary,
        uint256 amount
        );

    event ClaimAccepted(bytes32 indexed claimId);

    event ClaimDenied(bytes32 indexed claimId);

    function createClaim(
        address beneficiary,
        uint256 amount
        )
        external;

    function acceptClaim(bytes32 claimId)
        external;

    function denyClaim(bytes32 claimId)
        external;
}

// File: @api3-contracts/api3-pool/contracts/interfaces/IIouUtils.sol

pragma solidity 0.6.12;




interface IIouUtils is IClaimUtils {
    event IouCreated(
        bytes32 indexed iouId,
        address indexed userAddress,
        uint256 amountInShares,
        bytes32 indexed claimId,
        IApi3State.ClaimStatus redemptionCondition
        );

    event IouRedeemed(bytes32 indexed iouId, uint256 amount);

    event IouDeleted(bytes32 indexed iouId);

    function redeem(bytes32 iouId)
        external;
}

// File: @api3-contracts/api3-pool/contracts/interfaces/IVestingUtils.sol

pragma solidity 0.6.12;



interface IVestingUtils is IIouUtils {
    event VestingCreated(
        bytes32 indexed vestingId,
        address indexed userAddress,
        uint256 amount,
        uint256 vestingEpoch
        );

    event VestingResolved(bytes32 indexed vestingId);

    function vest(bytes32 vestingId)
        external;
}

// File: @api3-contracts/api3-pool/contracts/interfaces/IStakeUtils.sol

pragma solidity 0.6.12;



interface IStakeUtils is IVestingUtils {
    event Staked(
        address indexed userAddress,
        uint256 amountInShares
        );
    
    event UpdatedDelegate(
        address indexed userAddress,
        address indexed delegate
        );

    event Collected(
        address indexed userAddress,
        uint256 vestedRewards,
        uint256 instantRewards
        );

    function stake(address userAddress)
        external;

    function updateDelegate(address delegate)
        external;

    function collect(address userAddress)
        external;
}

// File: @api3-contracts/api3-pool/contracts/interfaces/IPoolUtils.sol

pragma solidity 0.6.12;



interface IPoolUtils is IStakeUtils {
    event Pooled(
        address indexed userAddress,
        uint256 amount,
        uint256 amountInShares
        );
    
    event RequestedToUnpool(address indexed userAddress);

    event Unpooled(
        address indexed userAddress,
        uint256 amount,
        uint256 amountInShares
    );

    function pool(uint256 amount)
        external;

    function requestToUnpool()
        external;

    function unpool(uint256 amountInShares)
        external;
}

// File: @api3-contracts/api3-pool/contracts/interfaces/ITransferUtils.sol

pragma solidity 0.6.12;



interface ITransferUtils is IPoolUtils {
    event Deposited(
        address indexed sourceAddress,
        uint256 amount,
        address indexed userAddress
        );
    
    event DepositedWithVesting(
        address indexed sourceAddress,
        uint256 amount,
        address indexed userAddress,
        uint256 vestingEpoch
        );
    
    event Withdrawn(
        address indexed userAddress,
        address destinationAddress,
        uint256 amount
        );
    
    event AddedVestedRewards(
        address indexed sourceAddress,
        uint256 amount,
        uint256 indexed epochIndex
        );
    
    event AddedInstantRewards(
        address indexed sourceAddress,
        uint256 amount,
        uint256 indexed epochIndex
        );

    function deposit(
        address sourceAddress,
        uint256 amount,
        address userAddress
        )
        external;

    function depositWithVesting(
        address sourceAddress,
        uint256 amount,
        address userAddress,
        uint256 vestingStart,
        uint256 vestingEnd
        )
        external;

    function withdraw(
        address destinationAddress,
        uint256 amount
        )
        external;

    function addVestedRewards(
        address sourceAddress,
        uint256 amount
        )
        external;

    function addInstantRewards(
        address sourceAddress,
        uint256 amount
        )
        external;
}

// File: @api3-contracts/api3-pool/contracts/interfaces/IApi3Pool.sol

pragma solidity 0.6.12;



interface IApi3Pool is ITransferUtils {}

// File: contracts/interfaces/ITimelockManager.sol

pragma solidity 0.6.12;


interface ITimelockManager {
    event Api3PoolUpdated(address api3PoolAddress);

    event RevertedTimelock(
        address indexed recipient,
        address destination,
        uint256 amount
        );

    event PermittedTimelockToBeReverted(address recipient);

    event TransferredAndLocked(
        address source,
        address indexed recipient,
        uint256 amount,
        uint256 releaseStart,
        uint256 releaseEnd
        );

    event Withdrawn(
        address indexed recipient,
        uint256 amount
        );

    event WithdrawnToPool(
        address indexed recipient,
        address api3PoolAddress,
        address beneficiary
        );

    function updateApi3Pool(address api3PoolAddress)
        external;

    function revertTimelock(
        address recipient,
        address destination
        )
        external;

    function permitTimelockToBeReverted()
        external;

    function transferAndLock(
        address source,
        address recipient,
        uint256 amount,
        uint256 releaseStart,
        uint256 releaseEnd
        )
        external;

    function transferAndLockMultiple(
        address source,
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint256[] calldata releaseStarts,
        uint256[] calldata releaseEnds
        )
        external;

    function withdraw()
        external;

    function withdrawToPool(
        address api3PoolAddress,
        address beneficiary
        )
        external;

    function getWithdrawable(address recipient)
        external
        view
        returns(uint256 withdrawable);

    function getTimelock(address recipient)
        external
        view
        returns (
            uint256 totalAmount,
            uint256 remainingAmount,
            uint256 releaseStart,
            uint256 releaseEnd
            );

    function getRemainingAmount(address recipient)
        external
        view
        returns (uint256 remainingAmount);

    function getIfTimelockIsRevertible(address recipient)
        external
        view
        returns (bool revertStatus);
}

// File: contracts/TimelockManager.sol

pragma solidity 0.6.12;







/// @title Contract that the API3 DAO uses to timelock API3 tokens
/// @notice The owner of TimelockManager (i.e., API3 DAO) can send tokens to
/// TimelockManager to timelock them. These tokens will then be vested to their
/// recipient linearly, starting from releaseStart and ending at releaseEnd of
/// the respective timelock.
/// Alternatively, if the owner of TimelockManager (i.e., API3 DAO) sets the
/// api3Pool address, the token recipients can transfer their locked tokens
/// from TimelockManager to api3Pool. These tokens will remain timelocked
/// (i.e., will not be withdrawable) at api3Pool until they are vested
/// according to their respective schedule.
contract TimelockManager is Ownable, ITimelockManager {
    using SafeMath for uint256;

    /// @dev If an address has permitted the owner of this contract (i.e., the
    /// API3 DAO) to revert (i.e., cancel and withdraw the tokens) their
    /// timelock
    mapping(address => bool) private permittedTimelockToBeReverted;

    struct Timelock {
        uint256 totalAmount;
        uint256 remainingAmount;
        uint256 releaseStart;
        uint256 releaseEnd;
        }

    IApi3Token public immutable api3Token;
    IApi3Pool public api3Pool;
    mapping(address => Timelock) public timelocks;

    /// @dev api3Pool is not initialized in the constructor because this
    /// contract will be deployed before api3Pool
    /// @param api3TokenAddress Address of the API3 token contract
    /// @param timelockManagerOwner Address that will receive the ownership of
    /// the TimelockManager contract (i.e., the API3 DAO)
    constructor(
        address api3TokenAddress,
        address timelockManagerOwner
        )
        public
    {
        api3Token = IApi3Token(api3TokenAddress);
        transferOwnership(timelockManagerOwner);
    }

    /// @notice Called by the owner (i.e., API3 DAO) to set the address of
    /// api3Pool, which token recipients can transfer their tokens to
    /// @param api3PoolAddress Address of the API3 pool contract
    function updateApi3Pool(address api3PoolAddress)
        external
        override
        onlyOwner
    {
        require(
            address(api3Pool) != api3PoolAddress,
            "Input will not update state"
        );
        api3Pool = IApi3Pool(api3PoolAddress);
        emit Api3PoolUpdated(api3PoolAddress);
    }

    /// @notice Called by the owner (i.e., API3 DAO) to revert the timelock of
    /// a recipient, given that they have given permission beforehand
    /// @param recipient Original recipient of tokens
    /// @param destination Destination of the tokens locked by the reverted
    /// timelock
    function revertTimelock(
        address recipient,
        address destination
        )
        external
        override
        onlyOwner
        onlyIfRecipientHasRemainingTokens(recipient)
    {
        require(
            destination != address(0),
            "Invalid destination"
            );
        require(
            permittedTimelockToBeReverted[recipient],
            "Not permitted to revert timelock"
            );
        // Reset permission automatically
        permittedTimelockToBeReverted[recipient] = false;
        uint256 remaining = timelocks[recipient].remainingAmount;
        timelocks[recipient].remainingAmount = 0;
        require(
            api3Token.transfer(destination, remaining),
            "API3 token transfer failed"
            );
        emit RevertedTimelock(recipient, destination, remaining);
    }

    /// @notice Permit the owner (i.e., API3 DAO) to revert the caller's
    /// timelock
    /// @dev To be used when the timelock has been created with incorrect
    /// parameters (for example with releaseEnd at infinity)
    function permitTimelockToBeReverted()
        external
        override
        onlyIfRecipientHasRemainingTokens(msg.sender)
    {
        require(
            !permittedTimelockToBeReverted[msg.sender],
            "Input will not update state"
        );
        permittedTimelockToBeReverted[msg.sender] = true;
        emit PermittedTimelockToBeReverted(msg.sender);
    }

    /// @notice Transfers API3 tokens to this contract and timelocks them
    /// @dev source needs to approve() this contract to transfer amount number
    /// of tokens beforehand.
    /// A recipient cannot have multiple timelocks.
    /// @param source Source of tokens
    /// @param recipient Recipient of tokens
    /// @param amount Amount of tokens
    /// @param releaseStart Start of release time
    /// @param releaseEnd End of release time
    function transferAndLock(
        address source,
        address recipient,
        uint256 amount,
        uint256 releaseStart,
        uint256 releaseEnd
        )
        public
        override
        onlyOwner
    {
        require(
            timelocks[recipient].remainingAmount == 0,
            "Recipient has remaining tokens"
            );
        require(amount != 0, "Amount cannot be 0");
        require(
            releaseEnd > releaseStart,
            "releaseEnd not larger than releaseStart"
            );
        require(
            releaseStart > now,
            "releaseStart not in the future"
            );
        timelocks[recipient] = Timelock({
            totalAmount: amount,
            remainingAmount: amount,
            releaseStart: releaseStart,
            releaseEnd: releaseEnd
            });
        require(
            api3Token.transferFrom(source, address(this), amount),
            "API3 token transferFrom failed"
            );
        emit TransferredAndLocked(
            source,
            recipient,
            amount,
            releaseStart,
            releaseEnd
            );
    }

    /// @notice Convenience function that calls transferAndLock() multiple times
    /// @dev source is expected to be a single address, i.e., the API3 DAO.
    /// source needs to approve() this contract to transfer the sum of the
    /// amounts of tokens to be transferred and locked.
    /// @param source Source of tokens
    /// @param recipients Array of recipients of tokens
    /// @param amounts Array of amounts of tokens
    /// @param releaseStarts Array of starts of release times
    /// @param releaseEnds Array of ends of release times
    function transferAndLockMultiple(
        address source,
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint256[] calldata releaseStarts,
        uint256[] calldata releaseEnds
        )
        external
        override
        onlyOwner
    {
        require(
            recipients.length == amounts.length
                && recipients.length == releaseStarts.length
                && recipients.length == releaseEnds.length,
            "Parameters are of unequal length"
            );
        require(
            recipients.length <= 30,
            "Parameters are longer than 30"
            );
        for (uint256 ind = 0; ind < recipients.length; ind++)
        {
            transferAndLock(
                source,
                recipients[ind],
                amounts[ind],
                releaseStarts[ind],
                releaseEnds[ind]
                );
        }
    }

    /// @notice Used by the recipient to withdraw tokens
    function withdraw()
        external
        override
        onlyIfRecipientHasRemainingTokens(msg.sender)
    {
        address recipient = msg.sender;
        uint256 withdrawable = getWithdrawable(recipient);
        require(
            withdrawable != 0,
            "No withdrawable tokens yet"
            );
        timelocks[recipient].remainingAmount = timelocks[recipient].remainingAmount.sub(withdrawable);
        require(
            api3Token.transfer(recipient, withdrawable),
            "API3 token transfer failed"
            );
        emit Withdrawn(
            recipient,
            withdrawable
            );
    }

    /// @notice Used by the recipient to withdraw their tokens to the API3 pool
    /// @dev We ask the recipient to provide api3PoolAddress as a form of
    /// validation, i.e., the recipient confirms that the API3 pool address set
    /// at this contract is correct
    /// @param api3PoolAddress Address of the API3 pool contract
    /// @param beneficiary Address that the tokens will be deposited to the
    /// pool contract on behalf of
    function withdrawToPool(
        address api3PoolAddress,
        address beneficiary
        )
        external
        override
        onlyIfRecipientHasRemainingTokens(msg.sender)
    {
        require(
            beneficiary != address(0),
            "beneficiary cannot be 0"
            );
        require(address(api3Pool) != address(0), "API3 pool not set yet");
        require(
            address(api3Pool) == api3PoolAddress,
            "API3 pool addresses do not match"
            );
        address recipient = msg.sender;
        uint256 withdrawable = getWithdrawable(recipient);
        uint256 remaining = timelocks[recipient].remainingAmount;
        uint256 timelocked = remaining.sub(withdrawable);
        timelocks[recipient].remainingAmount = 0;
        // Approve the total amount
        api3Token.approve(address(api3Pool), remaining);
        // Deposit the funds that are withdrawable without vesting
        if (withdrawable != 0)
        {
            api3Pool.deposit(
                address(this),
                withdrawable,
                beneficiary
                );
        }
        // Deposit the funds that are still timelocked with vesting.
        // The vesting will continue the same way at the pool, released
        // linearly.
        if (timelocked != 0)
        {
            api3Pool.depositWithVesting(
                address(this),
                timelocked,
                beneficiary,
                now > timelocks[recipient].releaseStart ? now : timelocks[recipient].releaseStart,
                timelocks[recipient].releaseEnd
                );
        }
        emit WithdrawnToPool(
            recipient,
            api3PoolAddress,
            beneficiary
            );
    }

    /// @notice Returns the amount of tokens a recipient can currently withdraw
    /// @param recipient Address of the recipient
    /// @return withdrawable Amount of tokens withdrawable by the recipient
    function getWithdrawable(address recipient)
        public
        view
        override
        returns(uint256 withdrawable)
    {
        Timelock storage timelock = timelocks[recipient];
        uint256 unlocked = getUnlocked(recipient);
        uint256 withdrawn = timelock.totalAmount.sub(timelock.remainingAmount);
        withdrawable = unlocked.sub(withdrawn);
    }

    /// @notice Returns the amount of tokens that was unlocked for the
    /// recipient to date. Includes both withdrawn and non-withdrawn tokens.
    /// @param recipient Address of the recipient
    /// @return unlocked Amount of tokens unlocked for the recipient
    function getUnlocked(address recipient)
        private
        view
        returns(uint256 unlocked)
    {
        Timelock storage timelock = timelocks[recipient];
        if (now <= timelock.releaseStart)
        {
            unlocked = 0;
        }
        else if (now >= timelock.releaseEnd)
        {
            unlocked = timelock.totalAmount;
        }
        else
        {
            uint256 passedTime = now.sub(timelock.releaseStart);
            uint256 totalTime = timelock.releaseEnd.sub(timelock.releaseStart);
            unlocked = timelock.totalAmount.mul(passedTime).div(totalTime);
        }
    }

    /// @notice Returns the details of a timelock
    /// @param recipient Recipient of tokens
    /// @return totalAmount Total amount of tokens
    /// @return remainingAmount Remaining amount of tokens to be withdrawn
    /// @return releaseStart Release start time
    /// @return releaseEnd Release end time
    function getTimelock(address recipient)
        external
        view
        override
        returns (
            uint256 totalAmount,
            uint256 remainingAmount,
            uint256 releaseStart,
            uint256 releaseEnd
            )
    {
        Timelock storage timelock = timelocks[recipient];
        totalAmount = timelock.totalAmount;
        remainingAmount = timelock.remainingAmount;
        releaseStart = timelock.releaseStart;
        releaseEnd = timelock.releaseEnd;
    }

    /// @notice Returns remaining amount of a timelock
    /// @dev Provided separately to be used with Etherscan's "Read"
    /// functionality, in case getTimelock() output is too complicated for the
    /// user.
    /// @param recipient Recipient of tokens
    /// @return remainingAmount Remaining amount of tokens to be withdrawn
    function getRemainingAmount(address recipient)
        external
        view
        override
        returns (uint256 remainingAmount)
    {
        remainingAmount = timelocks[recipient].remainingAmount;
    }

    /// @notice Returns if the recipient's timelock is revertible
    /// @param recipient Recipient of tokens
    /// @return revertStatus If the recipient's timelock is revertible
    function getIfTimelockIsRevertible(address recipient)
        external
        view
        override
        returns (bool revertStatus)
    {
        revertStatus = permittedTimelockToBeReverted[recipient];
    }

    /// @dev Reverts if the recipient does not have remaining tokens
    modifier onlyIfRecipientHasRemainingTokens(address recipient)
    {
        require(
            timelocks[recipient].remainingAmount != 0,
            "Recipient does not have remaining tokens"
            );
        _;
    }
}
