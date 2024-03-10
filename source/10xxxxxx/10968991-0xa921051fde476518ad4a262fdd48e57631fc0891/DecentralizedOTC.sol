// File: contracts/util/TransferETHInterface.sol

pragma solidity 0.6.6;


interface TransferETHInterface {
    receive() external payable;

    event LogTransferETH(address indexed from, address indexed to, uint256 value);
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

// File: contracts/bondToken/BondTokenInterface.sol

pragma solidity 0.6.6;




interface BondTokenInterface is TransferETHInterface, IERC20 {
    event LogExpire(uint128 rateNumerator, uint128 rateDenominator, bool firstTime);

    function mint(address account, uint256 amount) external returns (bool success);

    function expire(uint128 rateNumerator, uint128 rateDenominator)
        external
        returns (bool firstTime);

    function burn(uint256 amount) external returns (bool success);

    function burnAll() external returns (uint256 amount);

    function isMinter(address account) external view returns (bool minter);

    function getRate() external view returns (uint128 rateNumerator, uint128 rateDenominator);
}

// File: contracts/DecentralizedOTC/ERC20OracleInterface.sol

pragma solidity 0.6.6;


interface ERC20OracleInterface {
    function getPrice() external view returns (uint256);
}

// File: contracts/DecentralizedOTC/PricingInterface.sol

pragma solidity 0.6.6;


interface PricingInterface {
    function pricing(
        int256 etherPriceE4,
        int256 strikePriceE4,
        int256 ethVolatilityE8,
        int256 untilMaturity
    ) external view returns (uint256);
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/math/SignedSafeMath.sol

pragma solidity ^0.6.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Multiplies two signed integers, reverts on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Subtracts two signed integers, reverts on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Adds two signed integers, reverts on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// File: @openzeppelin/contracts/utils/SafeCast.sol

pragma solidity ^0.6.0;


/**
 * @dev Wrappers over Solidity's uintXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// File: contracts/math/UseSafeMath.sol

pragma solidity ^0.6.0;





/**
 * @notice ((a - 1) / b) + 1 = (a + b -1) / b
 * for example a.add(10**18 -1).div(10**18) = a.sub(1).div(10**18) + 1
 */

library SafeMathDivRoundUp {
    using SafeMath for uint256;

    function divRoundUp(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        require(b > 0, errorMessage);
        return ((a - 1) / b) + 1;
    }

    function divRoundUp(uint256 a, uint256 b) internal pure returns (uint256) {
        return divRoundUp(a, b, "SafeMathDivRoundUp: modulo by zero");
    }
}


/**
 * @title UseSafeMath
 * @dev One can use SafeMath for not only uint256 but also uin64 or uint16,
 * and also can use SafeCast for uint256.
 * For example:
 *   uint64 a = 1;
 *   uint64 b = 2;
 *   a = a.add(b).toUint64() // `a` become 3 as uint64
 * In additionally, one can use SignedSafeMath and SafeCast.toUint256(int256) for int256.
 * In the case of the operation to the uint64 value, one need to cast the value into int256 in
 * advance to use `sub` as SignedSafeMath.sub not SafeMath.sub.
 * For example:
 *   int256 a = 1;
 *   uint64 b = 2;
 *   int256 c = 3;
 *   a = a.add(int256(b).sub(c)); // `a` become 0 as int256
 *   b = a.toUint256().toUint64(); // `b` become 0 as uint64
 */
abstract contract UseSafeMath {
    using SafeMath for uint256;
    using SafeMathDivRoundUp for uint256;
    using SafeMath for uint64;
    using SafeMathDivRoundUp for uint64;
    using SafeMath for uint16;
    using SignedSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;
}

// File: contracts/BondMakerInterface.sol

pragma solidity 0.6.6;


interface BondMakerInterface {
    event LogNewBond(
        bytes32 indexed bondID,
        address bondTokenAddress,
        uint64 stableStrikePrice,
        bytes32 fnMapID
    );

    event LogNewBondGroup(uint256 indexed bondGroupID);

    event LogIssueNewBonds(uint256 indexed bondGroupID, address indexed issuer, uint256 amount);

    event LogReverseBondToETH(uint256 indexed bondGroupID, address indexed owner, uint256 amount);

    event LogExchangeEquivalentBonds(
        address indexed owner,
        uint256 indexed inputBondGroupID,
        uint256 indexed outputBondGroupID,
        uint256 amount
    );

    event LogTransferETH(address indexed from, address indexed to, uint256 value);

    function registerNewBond(uint256 maturity, bytes calldata fnMap)
        external
        returns (
            bytes32 bondID,
            address bondTokenAddress,
            uint64 solidStrikePrice,
            bytes32 fnMapID
        );

    function registerNewBondGroup(bytes32[] calldata bondIDList, uint256 maturity)
        external
        returns (uint256 bondGroupID);

    function issueNewBonds(uint256 bondGroupID) external payable returns (uint256 amount);

    function liquidateBond(uint256 bondGroupID, uint256 oracleHintID) external;

    function getBond(bytes32 bondID)
        external
        view
        returns (
            address bondAddress,
            uint256 maturity,
            uint64 solidStrikePrice,
            bytes32 fnMapID
        );

    function getFnMap(bytes32 fnMapID) external view returns (bytes memory fnMap);

    function getBondGroup(uint256 bondGroupID)
        external
        view
        returns (bytes32[] memory bondIDs, uint256 maturity);

    function generateBondID(uint256 maturity, bytes calldata functionHash)
        external
        pure
        returns (bytes32 bondID);
}

// File: contracts/util/Time.sol

pragma solidity 0.6.6;


abstract contract Time {
    function _getBlockTimestampSec() internal view returns (uint256 unixtimesec) {
        unixtimesec = now; // solium-disable-line security/no-block-members
    }
}

// File: contracts/util/TransferETH.sol

pragma solidity 0.6.6;



abstract contract TransferETH is TransferETHInterface {
    receive() external override payable {
        emit LogTransferETH(msg.sender, address(this), msg.value);
    }

    function _hasSufficientBalance(uint256 amount) internal view returns (bool ok) {
        address thisContract = address(this);
        return amount <= thisContract.balance;
    }

    /**
     * @notice transfer `amount` ETH to the `recipient` account with emitting log
     */
    function _transferETH(
        address payable recipient,
        uint256 amount,
        string memory errorMessage
    ) internal {
        require(_hasSufficientBalance(amount), errorMessage);
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "transferring Ether failed");
        emit LogTransferETH(address(this), recipient, amount);
    }

    function _transferETH(address payable recipient, uint256 amount) internal {
        _transferETH(recipient, amount, "TransferETH: transfer amount exceeds balance");
    }
}

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.6.0;





/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: contracts/util/DeployerRole.sol

pragma solidity 0.6.6;


abstract contract DeployerRole {
    address internal immutable _deployer;

    modifier onlyDeployer() {
        require(_isDeployer(msg.sender), "only deployer is allowed to call this function");
        _;
    }

    constructor() public {
        _deployer = msg.sender;
    }

    function _isDeployer(address account) internal view returns (bool) {
        return account == _deployer;
    }
}

// File: contracts/bondToken/BondToken.sol

pragma solidity 0.6.6;






contract BondToken is DeployerRole, BondTokenInterface, TransferETH, ERC20 {
    struct Frac128x128 {
        uint128 numerator;
        uint128 denominator;
    }

    Frac128x128 internal _rate;

    constructor(string memory name, string memory symbol) public ERC20(name, symbol) {
        _setupDecimals(8);
    }

    function mint(address account, uint256 amount)
        public
        virtual
        override
        onlyDeployer
        returns (bool success)
    {
        require(!isExpired(), "this token contract has expired");
        _mint(account, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount)
        public
        override(ERC20, IERC20)
        returns (bool success)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override(ERC20, IERC20) returns (bool success) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            allowance(sender, msg.sender).sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    /**
     * @dev Record the settlement price at maturity in the form of a fraction and let the bond
     * token expire.
     */
    function expire(uint128 rateNumerator, uint128 rateDenominator)
        public
        override
        onlyDeployer
        returns (bool isFirstTime)
    {
        isFirstTime = !isExpired();
        if (isFirstTime) {
            _setRate(Frac128x128(rateNumerator, rateDenominator));
        }

        emit LogExpire(rateNumerator, rateDenominator, isFirstTime);
    }

    function simpleBurn(address from, uint256 amount) public onlyDeployer returns (bool) {
        if (amount > balanceOf(from)) {
            return false;
        }

        _burn(from, amount);
        return true;
    }

    function burn(uint256 amount) public override returns (bool success) {
        if (!isExpired()) {
            return false;
        }

        _burn(msg.sender, amount);

        if (_rate.numerator != 0) {
            uint256 withdrawAmount = amount.mul(10**(18 - 8)).mul(_rate.numerator).div(
                _rate.denominator
            );
            _transferETH(msg.sender, withdrawAmount, "system error: insufficient balance");
        }

        return true;
    }

    function burnAll() public override returns (uint256 amount) {
        amount = balanceOf(msg.sender);
        bool success = burn(amount);
        if (!success) {
            amount = 0;
        }
    }

    /**
     * @dev rateDenominator never be zero due to div() function, thus initial _rateDenominator is 0
     * can be used for flag of non-expired;
     */
    function isExpired() public view returns (bool) {
        return _rate.denominator != 0;
    }

    function isMinter(address account) public override view returns (bool) {
        return _isDeployer(account);
    }

    function getRate()
        public
        override
        view
        returns (uint128 rateNumerator, uint128 rateDenominator)
    {
        rateNumerator = _rate.numerator;
        rateDenominator = _rate.denominator;
    }

    function _setRate(Frac128x128 memory rate) internal {
        require(
            rate.denominator != 0,
            "system error: the exchange rate must be non-negative number"
        );
        _rate = rate;
    }
}

// File: contracts/util/Polyline.sol

pragma solidity 0.6.6;



contract Polyline is UseSafeMath {
    struct Point {
        uint64 x; // Value of the x-axis of the x-y plane
        uint64 y; // Value of the y-axis of the x-y plane
    }

    struct LineSegment {
        Point left; // The left end of the line definition range
        Point right; // The right end of the line definition range
    }

    /**
     * @notice Return the value of y corresponding to x on the given line line in the form of
     * a rational number (numerator / denominator).
     * If you treat a line as a line segment instead of a line, you should run
     * includesDomain(line, x) to check whether x is included in the line's domain or not.
     * @dev To guarantee accuracy, the bit length of the denominator must be greater than or equal
     * to the bit length of x, and the bit length of the numerator must be greater than or equal
     * to the sum of the bit lengths of x and y.
     */
    function _mapXtoY(LineSegment memory line, uint64 x)
        internal
        pure
        returns (uint128 numerator, uint64 denominator)
    {
        int256 x1 = int256(line.left.x);
        int256 y1 = int256(line.left.y);
        int256 x2 = int256(line.right.x);
        int256 y2 = int256(line.right.y);

        require(x2 > x1, "must be left.x < right.x");

        denominator = uint64(x2 - x1);

        // Calculate y = ((x2 - x) * y1 + (x - x1) * y2) / (x2 - x1)
        // in the form of a fraction (numerator / denominator).
        int256 n = (x - x1) * y2 + (x2 - x) * y1;

        require(n >= 0, "underflow n");
        require(n < 2**128, "system error: overflow n");
        numerator = uint128(n);
    }

    /**
     * @notice Checking that a line segment is a line segment of a valid format.
     */
    function assertLineSegment(LineSegment memory segment) internal pure {
        uint64 x1 = segment.left.x;
        uint64 x2 = segment.right.x;
        require(x1 < x2, "must be left.x < right.x");
    }

    /**
     * @notice Checking that a polyline is a line graph of a valid form.
     */
    function assertPolyline(LineSegment[] memory polyline) internal pure {
        uint256 numOfSegment = polyline.length;
        require(numOfSegment > 0, "polyline must not be empty array");

        // About the first line segment.
        LineSegment memory firstSegment = polyline[0];

        // The beginning of the first line segment's domain is 0.
        require(
            firstSegment.left.x == uint64(0),
            "the x coordinate of left end of the first segment is 0"
        );
        // The value of y when x is 0 is 0.
        require(
            firstSegment.left.y == uint64(0),
            "the y coordinate of left end of the first segment is 0"
        );

        // About the last line segment.
        LineSegment memory lastSegment = polyline[numOfSegment - 1];

        // The slope of the last line segment should be between 0 and 1.
        int256 gradientNumerator = int256(lastSegment.right.y).sub(lastSegment.left.y);
        int256 gradientDenominator = int256(lastSegment.right.x).sub(lastSegment.left.x);
        require(
            gradientNumerator >= 0 && gradientNumerator <= gradientDenominator,
            "the gradient of last line segment must be non-negative number equal to or less than 1"
        );

        // Making sure that the first line segment is in the correct format.
        assertLineSegment(firstSegment);

        // The end of the domain of a segment and the beginning of the domain of the adjacent
        // segment coincide.
        for (uint256 i = 1; i < numOfSegment; i++) {
            LineSegment memory leftSegment = polyline[i - 1];
            LineSegment memory rightSegment = polyline[i];

            // Make sure that the i-th line segment is in the correct format.
            assertLineSegment(rightSegment);

            // Checking that the x-coordinates are same.
            require(
                leftSegment.right.x == rightSegment.left.x,
                "given polyline is not single-valued function."
            );

            // Checking that the y-coordinates are same.
            require(
                leftSegment.right.y == rightSegment.left.y,
                "given polyline is not continuous function"
            );
        }
    }

    /**
     * @notice zip a LineSegment structure to uint256
     * @return zip uint256( 0 ... 0 | x1 | y1 | x2 | y2 )
     */
    function zipLineSegment(LineSegment memory segment) internal pure returns (uint256 zip) {
        uint256 x1U256 = uint256(segment.left.x) << (64 + 64 + 64); // uint64
        uint256 y1U256 = uint256(segment.left.y) << (64 + 64); // uint64
        uint256 x2U256 = uint256(segment.right.x) << 64; // uint64
        uint256 y2U256 = uint256(segment.right.y); // uint64
        zip = x1U256 | y1U256 | x2U256 | y2U256;
    }

    /**
     * @notice unzip uint256 to a LineSegment structure
     */
    function unzipLineSegment(uint256 zip) internal pure returns (LineSegment memory) {
        uint64 x1 = uint64(zip >> (64 + 64 + 64));
        uint64 y1 = uint64(zip >> (64 + 64));
        uint64 x2 = uint64(zip >> 64);
        uint64 y2 = uint64(zip);
        return LineSegment({left: Point({x: x1, y: y1}), right: Point({x: x2, y: y2})});
    }

    /**
     * @notice unzip the fnMap to uint256[].
     */
    function decodePolyline(bytes memory fnMap) internal pure returns (uint256[] memory) {
        return abi.decode(fnMap, (uint256[]));
    }
}

// File: contracts/oracle/OracleInterface.sol

pragma solidity ^0.6.6;


// Oracle referenced by OracleProxy must implement this interface.
interface OracleInterface {
    // Returns if oracle is running.
    function alive() external view returns (bool);

    // Returns latest id.
    // The first id is 1 and 0 value is invalid as id.
    // Each price values and theirs timestamps are identified by id.
    // Ids are assigned incrementally to values.
    function latestId() external returns (uint256);

    // Returns latest price value.
    // decimal 8
    function latestPrice() external returns (uint256);

    // Returns timestamp of latest price.
    function latestTimestamp() external returns (uint256);

    // Returns price of id.
    function getPrice(uint256 id) external returns (uint256);

    // Returns timestamp of id.
    function getTimestamp(uint256 id) external returns (uint256);

    function getVolatility() external returns (uint256);

    function lastCalculatedVolatility() external returns (uint256);
}

// File: contracts/oracle/UseOracle.sol

pragma solidity 0.6.6;



abstract contract UseOracle {
    OracleInterface internal _oracleContract;

    constructor(address contractAddress) public {
        require(contractAddress != address(0), "contract should be non-zero address");
        _oracleContract = OracleInterface(contractAddress);
    }

    /// @notice Get the latest USD/ETH price and historical volatility using oracle.
    /// @return rateETH2USDE8 (10^-8 USD/ETH)
    /// @return volatilityE8 (10^-8)
    function _getOracleData() internal returns (uint256 rateETH2USDE8, uint256 volatilityE8) {
        rateETH2USDE8 = _oracleContract.latestPrice();
        volatilityE8 = _oracleContract.lastCalculatedVolatility();

        return (rateETH2USDE8, volatilityE8);
    }

    /// @notice Get the price of the oracle data with a minimum timestamp that does more than input value
    /// when you know the ID you are looking for.
    /// @param timestamp is the timestamp that you want to get price.
    /// @param hintID is the ID of the oracle data you are looking for.
    /// @return rateETH2USDE8 (10^-8 USD/ETH)
    function _getPriceOn(uint256 timestamp, uint256 hintID)
        internal
        returns (uint256 rateETH2USDE8)
    {
        uint256 latestID = _oracleContract.latestId();
        require(latestID != 0, "system error: the ID of oracle data should not be zero");

        require(hintID != 0, "the hint ID must not be zero");
        uint256 id = hintID;
        if (hintID > latestID) {
            id = latestID;
        }

        require(
            _oracleContract.getTimestamp(id) > timestamp,
            "there is no price data after maturity"
        );

        id--;
        while (id != 0) {
            if (_oracleContract.getTimestamp(id) <= timestamp) {
                break;
            }
            id--;
        }

        return _oracleContract.getPrice(id + 1);
    }
}

// File: contracts/bondTokenName/BondTokenNameInterface.sol

pragma solidity ^0.6.6;


/**
 * @title bond token name contract interface
 */
interface BondTokenNameInterface {
    function genBondTokenName(
        string calldata shortNamePrefix,
        string calldata longNamePrefix,
        uint256 maturity,
        uint256 solidStrikePriceE4
    ) external pure returns (string memory shortName, string memory longName);

    function getBondTokenName(
        uint256 maturity,
        uint256 solidStrikePriceE4,
        uint256 rateLBTWorthlessE4
    ) external pure returns (string memory shortName, string memory longName);
}

// File: contracts/UseBondTokenName.sol

pragma solidity 0.6.6;



abstract contract UseBondTokenName {
    BondTokenNameInterface internal immutable _bondTokenNameContract;

    constructor(address contractAddress) public {
        require(contractAddress != address(0), "contract should be non-zero address");
        _bondTokenNameContract = BondTokenNameInterface(contractAddress);
    }
}

// File: contracts/BondMaker.sol

pragma solidity 0.6.6;










contract BondMaker is
    UseSafeMath,
    BondMakerInterface,
    Time,
    TransferETH,
    Polyline,
    UseOracle,
    UseBondTokenName
{
    uint8 internal constant DECIMALS_OF_BOND_AMOUNT = 8;

    address internal immutable LIEN_TOKEN_ADDRESS;
    uint256 internal immutable MATURITY_SCALE;

    uint256 public nextBondGroupID = 1;

    /**
     * @dev The contents in this internal storage variable can be seen by getBond function.
     */
    struct BondInfo {
        uint256 maturity;
        BondToken contractInstance;
        uint64 solidStrikePriceE4;
        bytes32 fnMapID;
    }
    mapping(bytes32 => BondInfo) internal _bonds;

    /**
     * @notice mapping fnMapID to polyline
     * @dev The contents in this internal storage variable can be seen by getFnMap function.
     */
    mapping(bytes32 => LineSegment[]) internal _registeredFnMap;

    /**
     * @dev The contents in this internal storage variable can be seen by getBondGroup function.
     */
    struct BondGroup {
        bytes32[] bondIDs;
        uint256 maturity;
    }
    mapping(uint256 => BondGroup) internal _bondGroupList;

    constructor(
        address oracleAddress,
        address lienTokenAddress,
        address bondTokenNameAddress,
        uint256 maturityScale
    ) public UseOracle(oracleAddress) UseBondTokenName(bondTokenNameAddress) {
        LIEN_TOKEN_ADDRESS = lienTokenAddress;
        require(maturityScale != 0, "MATURITY_SCALE must be positive");
        MATURITY_SCALE = maturityScale;
    }

    /**
     * @notice Create bond token contract.
     * The name of this bond token is its bond ID.
     * @dev To convert bytes32 to string, encode its bond ID at first, then convert to string.
     * The symbol of any bond token with bond ID is either SBT or LBT;
     * As SBT is a special case of bond token, any bond token which does not match to the form of
     * SBT is defined as LBT.
     */
    function registerNewBond(uint256 maturity, bytes memory fnMap)
        public
        override
        returns (
            bytes32,
            address,
            uint64,
            bytes32
        )
    {
        require(maturity > _getBlockTimestampSec(), "the maturity has already expired");
        require(maturity < _getBlockTimestampSec() + 365 days, "the maturity is too far");
        require(maturity % MATURITY_SCALE == 0, "maturity must be HH:00:00");

        bytes32 bondID = generateBondID(maturity, fnMap);

        // Check if the same form of bond is already registered.
        // Cannot detect if the bond is described in a different polyline while two are
        // mathematically equivalent.
        require(
            address(_bonds[bondID].contractInstance) == address(0),
            "already register given bond type"
        );

        // Register function mapping if necessary.
        bytes32 fnMapID = generateFnMapID(fnMap);
        if (_registeredFnMap[fnMapID].length == 0) {
            uint256[] memory polyline = decodePolyline(fnMap);
            for (uint256 i = 0; i < polyline.length; i++) {
                _registeredFnMap[fnMapID].push(unzipLineSegment(polyline[i]));
            }

            assertPolyline(_registeredFnMap[fnMapID]);
            require(_registeredFnMap[fnMapID].length == 2, "the number of segments must be 2");
        }

        uint64 solidStrikePrice = _getSolidStrikePrice(_registeredFnMap[fnMapID]);
        uint64 rateLBTWorthless = _getRateLBTWorthless(_registeredFnMap[fnMapID]);

        (string memory shortName, string memory longName) = _bondTokenNameContract.getBondTokenName(
            maturity,
            solidStrikePrice,
            rateLBTWorthless
        );

        BondToken bondTokenContract = _createNewBondToken(longName, shortName);

        // Set bond info to storage.
        _bonds[bondID] = BondInfo({
            maturity: maturity,
            contractInstance: bondTokenContract,
            solidStrikePriceE4: solidStrikePrice,
            fnMapID: fnMapID
        });

        emit LogNewBond(bondID, address(bondTokenContract), solidStrikePrice, fnMapID);

        return (bondID, address(bondTokenContract), solidStrikePrice, fnMapID);
    }

    function _assertBondGroup(bytes32[] memory bondIDs, uint256 maturity) internal view {
        require(bondIDs.length == 2, "the bond group should consist of 2 bonds");

        {
            (, , uint64 solidStrikePrice, ) = getBond(bondIDs[0]);
            require(solidStrikePrice != 0, "the first bond must be SBT");
        }

        /**
         * @dev Count the number of the end points on x axis. In the case of a simple SBT/LBT split,
         * 3 for SBT plus 3 for LBT equals to 6.
         * In the case of SBT with the strike price 100, (x,y) = (0,0), (100,100), (200,100) defines
         * the form of SBT on the field.
         * In the case of LBT with the strike price 100, (x,y) = (0,0), (100,0), (200,100) defines
         * the form of LBT on the field.
         * Right hand side area of the last grid point is expanded on the last line to the infinity.
         * @param nextBreakPointIndex returns the number of unique points on x axis.
         * In the case of SBT and LBT with the strike price 100, x = 0,100,200 are the unique points
         * and the number is 3.
         */
        uint256 numOfBreakPoints = 0;
        for (uint256 i = 0; i < bondIDs.length; i++) {
            BondInfo storage bond = _bonds[bondIDs[i]];
            require(bond.maturity == maturity, "the maturity of the bonds must be same");
            LineSegment[] storage polyline = _registeredFnMap[bond.fnMapID];
            numOfBreakPoints = numOfBreakPoints.add(polyline.length);
        }

        uint256 nextBreakPointIndex = 0;
        uint64[] memory rateBreakPoints = new uint64[](numOfBreakPoints);
        for (uint256 i = 0; i < bondIDs.length; i++) {
            BondInfo storage bond = _bonds[bondIDs[i]];
            LineSegment[] storage segments = _registeredFnMap[bond.fnMapID];
            for (uint256 j = 0; j < segments.length; j++) {
                uint64 breakPoint = segments[j].right.x;
                bool ok = false;

                for (uint256 k = 0; k < nextBreakPointIndex; k++) {
                    if (rateBreakPoints[k] == breakPoint) {
                        ok = true;
                        break;
                    }
                }

                if (ok) {
                    continue;
                }

                rateBreakPoints[nextBreakPointIndex] = breakPoint;
                nextBreakPointIndex++;
            }
        }

        for (uint256 k = 0; k < rateBreakPoints.length; k++) {
            uint64 rate = rateBreakPoints[k];
            uint256 totalBondPriceN = 0;
            uint256 totalBondPriceD = 1;
            for (uint256 i = 0; i < bondIDs.length; i++) {
                BondInfo storage bond = _bonds[bondIDs[i]];
                LineSegment[] storage segments = _registeredFnMap[bond.fnMapID];
                (uint256 segmentIndex, bool ok) = _correspondSegment(segments, rate);

                require(ok, "invalid domain expression");

                (uint128 n, uint64 d) = _mapXtoY(segments[segmentIndex], rate);

                if (n != 0) {
                    // totalBondPrice += (n / d);
                    // N = D*n + N*d, D = D*d
                    totalBondPriceN = totalBondPriceD.mul(n).add(totalBondPriceN.mul(d));
                    totalBondPriceD = totalBondPriceD.mul(d);
                }
            }
            /**
             * @dev Ensure that totalBondPrice (= totalBondPriceN / totalBondPriceD) is the same
             * with rate. Because we need 1 Ether to mint a unit of each bond token respectively,
             * the sum of strike price (USD) per a unit of bond token is the same with USD/ETH
             * rate at maturity.
             */
            require(
                totalBondPriceN == totalBondPriceD.mul(rate),
                "the total price at any rateBreakPoints should be the same value as the rate"
            );
        }
    }

    /**
     * @notice Collect bondIDs that regenerate the original ETH, and group them as a bond group.
     * Any bond is described as a set of linear functions(i.e. polyline),
     * so we can easily check if the set of bondIDs are well-formed by looking at all the end
     * points of the lines.
     */
    function registerNewBondGroup(bytes32[] memory bondIDs, uint256 maturity)
        public
        override
        returns (uint256 bondGroupID)
    {
        _assertBondGroup(bondIDs, maturity);

        // Get and increment next bond group ID
        bondGroupID = nextBondGroupID;
        nextBondGroupID = nextBondGroupID.add(1);

        _bondGroupList[bondGroupID] = BondGroup(bondIDs, maturity);

        emit LogNewBondGroup(bondGroupID);

        return bondGroupID;
    }

    /**
     * @notice A user needs to issue a bond via BondGroup in order to guarantee that the total value
     * of bonds in the bond group equals to the input Ether except for about 0.2% fee (accurately 2/1002).
     */
    function issueNewBonds(uint256 bondGroupID) public override payable returns (uint256) {
        require(bondGroupID < nextBondGroupID, "the bond group does not exist");
        BondGroup storage bondGroup = _bondGroupList[bondGroupID];
        bytes32[] storage bondIDs = bondGroup.bondIDs;
        require(bondIDs.length != 0, "system error: the list of bond ID must be non-empty");
        require(_getBlockTimestampSec() < bondGroup.maturity, "the maturity has already expired");

        uint256 fee = msg.value.mul(2).divRoundUp(1002);

        uint256 amount = msg.value.sub(fee).div(10**10); // ether's decimal is 18 and that of LBT is 8;
        require(amount != 0, "the minting amount must be non-zero");

        for (uint256 i = 0; i < bondIDs.length; i++) {
            _issueNewBond(bondIDs[i], msg.sender, amount);
        }

        _transferETH(payable(LIEN_TOKEN_ADDRESS), fee);

        emit LogIssueNewBonds(bondGroupID, msg.sender, amount);

        return amount;
    }

    /**
     * @notice Distributes ETH to the bond token holders after maturity date based on the oracle price.
     * @param oracleHintID is manyally set to be smaller number than the oracle latestId when the caller wants to save gas.
     */
    function liquidateBond(uint256 bondGroupID, uint256 oracleHintID) public override {
        require(bondGroupID < nextBondGroupID, "the bond group does not exist");
        if (oracleHintID == 0) {
            _distributeETH2BondTokenContract(bondGroupID, _oracleContract.latestId());
        } else {
            _distributeETH2BondTokenContract(bondGroupID, oracleHintID);
        }
    }

    /**
     * @notice Returns multiple information for the bondID.
     */
    function getBond(bytes32 bondID)
        public
        override
        view
        returns (
            address bondTokenAddress,
            uint256 maturity,
            uint64 solidStrikePrice,
            bytes32 fnMapID
        )
    {
        BondInfo memory bondInfo = _bonds[bondID];
        bondTokenAddress = address(bondInfo.contractInstance);
        maturity = bondInfo.maturity;
        solidStrikePrice = bondInfo.solidStrikePriceE4;
        fnMapID = bondInfo.fnMapID;
    }

    /**
     * @dev Returns polyline for the fnMapID.
     */
    function getFnMap(bytes32 fnMapID) public override view returns (bytes memory) {
        LineSegment[] storage segments = _registeredFnMap[fnMapID];
        uint256[] memory polyline = new uint256[](segments.length);
        for (uint256 i = 0; i < segments.length; i++) {
            polyline[i] = zipLineSegment(segments[i]);
        }
        return abi.encode(polyline);
    }

    /**
     * @dev Returns all the bondIDs and their maturity for the bondGroupID.
     */
    function getBondGroup(uint256 bondGroupID)
        public
        virtual
        override
        view
        returns (bytes32[] memory bondIDs, uint256 maturity)
    {
        BondGroup memory bondGroup = _bondGroupList[bondGroupID];
        bondIDs = bondGroup.bondIDs;
        maturity = bondGroup.maturity;
    }

    /**
     * @dev Returns keccak256 for the fnMap.
     */
    function generateFnMapID(bytes memory fnMap) public pure returns (bytes32) {
        return keccak256(fnMap);
    }

    /**
     * @dev Returns keccak256 for the pair of maturity and fnMap.
     */
    function generateBondID(uint256 maturity, bytes memory fnMap)
        public
        override
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(maturity, fnMap));
    }

    function _createNewBondToken(string memory name, string memory symbol)
        internal
        virtual
        returns (BondToken)
    {
        return new BondToken(name, symbol);
    }

    function _issueNewBond(
        bytes32 bondID,
        address account,
        uint256 amount
    ) internal {
        BondToken bondTokenContract = _bonds[bondID].contractInstance;
        require(address(bondTokenContract) != address(0), "the bond is not registered");
        require(bondTokenContract.mint(account, amount), "failed to mint bond token");
    }

    function _burnBond(
        bytes32 bondID,
        address account,
        uint256 amount
    ) internal {
        BondToken bondTokenContract = _bonds[bondID].contractInstance;
        require(address(bondTokenContract) != address(0), "the bond is not registered");
        require(bondTokenContract.simpleBurn(account, amount), "failed to burn bond token");
    }

    function _distributeETH2BondTokenContract(uint256 bondGroupID, uint256 oracleHintID) internal {
        BondGroup memory bondGroup = _bondGroupList[bondGroupID];
        require(bondGroup.bondIDs.length > 0, "the bond group does not exist");
        require(_getBlockTimestampSec() >= bondGroup.maturity, "the bond has not expired yet");

        // rateETH2USDE8 is the USD/ETH price multiplied by 10^8 returned from the oracle.
        uint256 rateETH2USDE8 = _getPriceOn(bondGroup.maturity, oracleHintID);

        // rateETH2USDE8 needs to be converted to rateETH2USDE4 as to match the decimal of the
        // values in segment.
        uint256 rateETH2USDE4 = rateETH2USDE8.div(10000);
        require(rateETH2USDE4 != 0, "system error: rate should be non-zero value");
        require(
            rateETH2USDE4 < 2**64,
            "system error: rate should be less than the maximum value of uint64"
        );

        for (uint256 i = 0; i < bondGroup.bondIDs.length; i++) {
            bytes32 bondID = bondGroup.bondIDs[i];
            BondToken bondTokenContract = _bonds[bondID].contractInstance;
            require(address(bondTokenContract) != address(0), "the bond is not registered");

            LineSegment[] storage segments = _registeredFnMap[_bonds[bondID].fnMapID];

            (uint256 segmentIndex, bool ok) = _correspondSegment(segments, uint64(rateETH2USDE4));

            require(
                ok,
                "system error: did not found a segment whose price range include USD/ETH rate"
            );
            LineSegment storage segment = segments[segmentIndex];
            (uint128 n, uint64 _d) = _mapXtoY(segment, uint64(rateETH2USDE4));

            // uint64(-1) *  uint64(-1) < uint128(-1)
            uint128 d = uint128(_d) * uint128(rateETH2USDE4);

            uint256 totalSupply = bondTokenContract.totalSupply();
            bool expiredFlag = bondTokenContract.expire(n, d);

            if (expiredFlag) {
                uint256 payment = totalSupply.mul(10**(18 - 8)).mul(n).div(d);
                _transferETH(
                    address(bondTokenContract),
                    payment,
                    "system error: BondMaker's balance is less than payment"
                );
            }
        }
    }

    /**
     * @dev Return the strike price only when the form of polyline matches to the definition of SBT.
     * Check if the form is SBT even when the polyline is in a verbose style.
     */
    function _getSolidStrikePrice(LineSegment[] memory polyline) internal pure returns (uint64) {
        uint64 solidStrikePrice = polyline[0].right.x;

        if (solidStrikePrice == 0) {
            return 0;
        }

        for (uint256 i = 0; i < polyline.length; i++) {
            LineSegment memory segment = polyline[i];
            if (segment.right.y != solidStrikePrice) {
                return 0;
            }
        }

        return uint64(solidStrikePrice);
    }

    /**
     * @dev Only when the form of polyline matches to the definition of LBT, this function returns
     * the minimum USD/ETH rate that LBT is not worthless.
     * Check if the form is LBT even when the polyline is in a verbose style.
     */
    function _getRateLBTWorthless(LineSegment[] memory polyline) internal pure returns (uint64) {
        uint64 rateLBTWorthless = polyline[0].right.x;

        if (rateLBTWorthless == 0) {
            return 0;
        }

        for (uint256 i = 0; i < polyline.length; i++) {
            LineSegment memory segment = polyline[i];
            if (segment.right.y.add(rateLBTWorthless) != segment.right.x) {
                return 0;
            }
        }

        return uint64(rateLBTWorthless);
    }

    /**
     * @dev In order to calculate y axis value for the corresponding x axis value, we need to find
     * the place of domain of x value on the polyline.
     * As the polyline is already checked to be correctly formed, we can simply look from the right
     * hand side of the polyline.
     */
    function _correspondSegment(LineSegment[] memory segments, uint64 x)
        internal
        pure
        returns (uint256 i, bool ok)
    {
        i = segments.length;
        while (i > 0) {
            i--;
            if (segments[i].left.x <= x) {
                ok = true;
                break;
            }
        }
    }
}

// File: contracts/UseBondMaker.sol

pragma solidity 0.6.6;



abstract contract UseBondMaker {
    BondMakerInterface internal immutable _bondMakerContract;

    constructor(address contractAddress) public {
        require(contractAddress != address(0), "contract should be non-zero address");
        _bondMakerContract = BondMakerInterface(payable(contractAddress));
    }
}

// File: contracts/DecentralizedOTC/DecentralizedOTC.sol

pragma solidity 0.6.6;











contract DecentralizedOTC is UseOracle, UseBondMaker, UseSafeMath, Time {
    constructor(address bondMakerAddress, address oracleAddress)
        public
        UseOracle(oracleAddress)
        UseBondMaker(bondMakerAddress)
    {}

    int256 internal constant SQRT_YEAR_E8 = 561569229926;
    int256 internal constant SQRT_2PI_E8 = 250662827;
    uint256 internal constant MIN_EXCHANG_RATE_E8 = 0.000001 * 10**8;
    uint256 internal constant MAX_EXCHANG_RATE_E8 = 1000000 * 10**8;
    int256 internal constant MIN_ND1 = 0.1 * 10**4;
    int256 internal constant MAX_ND1 = 0.9 * 10**4;
    int256 internal constant MAX_SPREAD_E7 = 0.15 * 10**7; // 15%

    mapping(bytes32 => address) public deployer;

    /**
     * @notice ERC20pool is the amount of ERC20 deposit of a deployer.
     * @param ERC20Address is the target ERC20 token address.
     * @param spread is the fee base of the bid-ask spread.
     * @param isLBTSellPool is whether this pool is for the LBT sale or not.
     */
    struct PoolInfo {
        ERC20 ERC20Address;
        int16 spread;
        bool isLBTSellPool;
    }
    mapping(bytes32 => PoolInfo) public poolMap;

    struct OracleInfo {
        address oracleAddress;
        address calculatorAddress;
    }
    mapping(bytes32 => OracleInfo) public oracleInfo;

    event LogERC20TokenLBTSwap(
        bytes32 indexed poolID,
        address indexed sender,
        uint256 indexed bondGroupID,
        address ERC20Address,
        uint256 LBTAmount,
        uint256 ERC20Amount
    );

    event LogLBTERC20TokenSwap(
        bytes32 indexed poolID,
        address indexed sender,
        uint256 indexed bondGroupID,
        address ERC20Address,
        uint256 LBTAmount,
        uint256 ERC20Amount
    );

    event LogCreateERC20Pool(
        address indexed deployer,
        address indexed ERC20Address,
        bytes32 indexed poolID,
        int16 spread,
        bool isLBTSellPool
    );

    modifier isExistentPool(bytes32 erc20PoolID) {
        require(deployer[erc20PoolID] != address(0), "the pool does not exist");
        _;
    }

    /**
     * @notice providers set a pool and deposit to a pool.
     * If there is vesting(lockUp) setting, users of their pool transfer LBT to grants of the vesting ERC20 contract.
     */
    function setPoolMap(
        address ERC20Address,
        int16 spread,
        bool isLBTSellPool
    ) external returns (bytes32 erc20PoolID) {
        erc20PoolID = keccak256(abi.encode(msg.sender, ERC20Address, spread, isLBTSellPool));
        require(deployer[erc20PoolID] == address(0), "already registered");
        require(msg.sender != address(0), "deployer must be non-zero address");
        require(spread > -1000 && spread < 1000, "spread range must be -999~999");
        require(ERC20Address != address(0), "ERC20 address is 0x0");

        poolMap[erc20PoolID] = PoolInfo(ERC20(ERC20Address), spread, isLBTSellPool);
        deployer[erc20PoolID] = msg.sender;
        emit LogCreateERC20Pool(msg.sender, ERC20Address, erc20PoolID, spread, isLBTSellPool);
    }

    /**
     * @notice providers must provide LBT price caluculator and ERC20 price oracle.
     */
    function setProvider(
        bytes32 erc20PoolID,
        address oracleAddress,
        address calculatorAddress
    ) external isExistentPool(erc20PoolID) {
        require(msg.sender == deployer[erc20PoolID], "only deployer is allowed to execute");
        oracleInfo[erc20PoolID] = OracleInfo(oracleAddress, calculatorAddress);
    }

    function getOraclePrice(bytes32 erc20PoolID)
        public
        view
        isExistentPool(erc20PoolID)
        returns (uint256 priceE4)
    {
        ERC20OracleInterface oracleContract = ERC20OracleInterface(
            oracleInfo[erc20PoolID].oracleAddress
        );
        require(address(oracleContract) != address(0), "invalid ERC20 price oracle");
        return oracleContract.getPrice();
    }

    function _getEtherOraclePrice()
        internal
        virtual
        returns (uint256 etherPriceE4, uint256 volatilityE8)
    {
        uint256 etherPriceE8;
        (etherPriceE8, volatilityE8) = _getOracleData();
        etherPriceE4 = etherPriceE8.div(10**4);
    }

    /**
     * @notice Gets LBT data and market Ether data, and outputs the theoretical price of the LBT.
     */
    function getLBTTheoreticalPrice(
        bytes32 erc20PoolID,
        uint256 etherPriceE4,
        uint256 strikePriceE4,
        uint256 ethVolatilityE8,
        uint256 maturity
    ) public view isExistentPool(erc20PoolID) returns (uint256) {
        require(
            _getBlockTimestampSec() < maturity && _getBlockTimestampSec() >= maturity - 12 weeks,
            "LBT should not have expired and the maturity should not be so distant"
        );
        uint256 untilMaturity = maturity.sub(_getBlockTimestampSec());
        PricingInterface pricerContract = PricingInterface(
            oracleInfo[erc20PoolID].calculatorAddress
        );
        require(address(pricerContract) != address(0), "pricer contract is invalid");
        return
            pricerContract.pricing(
                etherPriceE4.toInt256(),
                strikePriceE4.toInt256(),
                ethVolatilityE8.toInt256(),
                untilMaturity.toInt256()
            );
    }

    /**
     * @notice Returns the exchange rate included spread.
     */
    function calcRateLBT2ERC20(
        bytes32 sbtID,
        bytes32 erc20PoolID,
        uint256 maturity
    ) public returns (uint256 rateLBT2ERC20E8) {
        PoolInfo memory pool = poolMap[erc20PoolID];
        (uint256 etherPriceE4, uint256 ethVolatilityE8) = _getEtherOraclePrice();
        (uint256 rateE8, uint256 lbtLeverageE4) = _calcRateLBT2ERC20ExcludedSpread(
            sbtID,
            erc20PoolID,
            etherPriceE4,
            ethVolatilityE8,
            maturity
        );
        require(rateE8 > MIN_EXCHANG_RATE_E8, "exchange rate is too small");
        require(rateE8 < MAX_EXCHANG_RATE_E8, "exchange rate is too large");

        uint256 volE8 = ethVolatilityE8 < 10**8 ? 10**8 : ethVolatilityE8 > 2 * 10**8
            ? 2 * 10**8
            : ethVolatilityE8;
        uint256 volTimesLevE4 = (volE8 * lbtLeverageE4) / 10**8;
        int256 spreadE7 = pool.spread *
            (pool.spread < 0 || volTimesLevE4 < 10**4 ? 10**4 : volTimesLevE4).toInt256();
        spreadE7 = spreadE7 > MAX_SPREAD_E7 ? MAX_SPREAD_E7 : spreadE7;

        if (pool.isLBTSellPool) {
            return rateE8.mul(uint256(10000000 + spreadE7)).div(10000000);
        } else {
            return rateE8.mul(uint256(10000000 - spreadE7)).div(10000000);
        }
    }

    /**
     * @dev Gets LBT data, and outputs the exchange rate excluded spread.
     */
    function _calcRateLBT2ERC20ExcludedSpread(
        bytes32 sbtID,
        bytes32 erc20PoolID,
        uint256 etherPriceE4,
        uint256 ethVolatilityE8,
        uint256 maturity
    ) internal view returns (uint256 rateLBT2ERC20E8, uint256 lbtLeverageE4) {
        require(
            ethVolatilityE8 != 0,
            "system error: the volatility of ETH should be non-zero value"
        );
        (uint256 lowestPriceE4, uint256 strikePriceE4) = _getLowestPrice(sbtID, etherPriceE4);
        uint256 lbtPriceE4 = getLBTTheoreticalPrice(
            erc20PoolID,
            etherPriceE4,
            strikePriceE4,
            ethVolatilityE8,
            maturity
        );
        if (lowestPriceE4 > lbtPriceE4) {
            lbtPriceE4 = lowestPriceE4;
        }
        require(lbtPriceE4 <= etherPriceE4, "LBT price needs to be less than ether price");
        require(lbtPriceE4 != 0, "This LBT is not available : 0-value");

        lbtLeverageE4 = calcLbtLeverage(
            etherPriceE4,
            strikePriceE4,
            ethVolatilityE8,
            maturity.sub(_getBlockTimestampSec()),
            lbtPriceE4
        );

        rateLBT2ERC20E8 = lbtPriceE4.mul(1e8).div(
            getOraclePrice(erc20PoolID),
            "ERC20 oracle price must be non-zero"
        );

        return (rateLBT2ERC20E8, lbtLeverageE4);
    }

    /**
     * @notice removes a decimal gap from rate.
     */
    function _applyDecimalGap(
        uint256 amount,
        ERC20 bondToken,
        ERC20 token
    ) private view returns (uint256) {
        uint256 n;
        uint256 d;

        uint8 decimalsOfBondToken = bondToken.decimals();
        uint8 decimalsOfToken = token.decimals();
        if (decimalsOfBondToken > decimalsOfToken) {
            d = decimalsOfBondToken - decimalsOfToken;
        } else if (decimalsOfBondToken < decimalsOfToken) {
            n = decimalsOfToken - decimalsOfBondToken;
        }

        // The consequent multiplication would overflow under extreme and non-blocking circumstances.
        require(n < 19 && d < 19, "decimal gap needs to be lower than 19");
        return amount.mul(10**n).div(10**d);
    }

    /**
     * @notice Before this function, approve is needed to be excuted.
     * Main function of this contract. Users exchange ERC20 tokens (like USDC Token) to LBT
     */
    function exchangeERC20ToLBT(
        uint256 bondGroupID,
        bytes32 erc20PoolID,
        uint256 ERC20Amount,
        uint256 expectedAmount,
        uint256 range
    ) public returns (uint256 LBTAmount) {
        LBTAmount = _exchangeERC20ToLBT(bondGroupID, erc20PoolID, ERC20Amount);
        if (expectedAmount != 0) {
            require(LBTAmount.mul(1000 + range).div(1000) >= expectedAmount, "out of price range");
        }
    }

    function _exchangeERC20ToLBT(
        uint256 bondGroupID,
        bytes32 erc20PoolID,
        uint256 ERC20Amount
    ) internal isExistentPool(erc20PoolID) returns (uint256 LBTAmount) {
        bytes32 lbtID;
        bytes32 sbtID;
        {
            (bytes32[] memory bonds, ) = _bondMakerContract.getBondGroup(bondGroupID);
            require(bonds.length == 2, "the bond group must include only 2 types of bond.");
            lbtID = bonds[1];
            sbtID = bonds[0];
        }

        (address contractAddress, uint256 maturity, , ) = _bondMakerContract.getBond(lbtID);
        require(contractAddress != address(0), "the bond is not registered");
        ERC20 bondToken = ERC20(contractAddress);

        PoolInfo memory pool = poolMap[erc20PoolID];
        require(pool.isLBTSellPool, "This pool is for buying LBT");

        ERC20 token = pool.ERC20Address;
        {
            uint256 rateE8 = calcRateLBT2ERC20(sbtID, erc20PoolID, maturity);
            LBTAmount = _applyDecimalGap(ERC20Amount.mul(1e8), token, bondToken).div(rateE8);
            require(LBTAmount != 0, "must transfer non-zero LBT amount");
        }

        require(
            token.transferFrom(msg.sender, deployer[erc20PoolID], ERC20Amount),
            "fail to transfer ERC20 token"
        );
        require(
            bondToken.transferFrom(deployer[erc20PoolID], msg.sender, LBTAmount),
            "fail to transfer LBT"
        );

        emit LogERC20TokenLBTSwap(
            erc20PoolID,
            msg.sender,
            bondGroupID,
            address(token),
            LBTAmount,
            ERC20Amount
        );
    }

    /**
     * @notice Before this function, approve is needed to be excuted.
     * Main function of this contract. Users exchange LBT to ERC20 tokens (like USDC Token)
     */
    function exchangeLBT2ERC20(
        uint256 bondGroupID,
        bytes32 erc20PoolID,
        uint256 LBTAmount,
        uint256 expectedAmount,
        uint256 range
    ) public returns (uint256 ERC20Amount) {
        ERC20Amount = _exchangeLBT2ERC20(bondGroupID, erc20PoolID, LBTAmount);
        if (expectedAmount != 0) {
            require(
                ERC20Amount.mul(1000 + range).div(1000) >= expectedAmount,
                "out of price range"
            );
        }
    }

    function _exchangeLBT2ERC20(
        uint256 bondGroupID,
        bytes32 erc20PoolID,
        uint256 LBTAmount
    ) internal isExistentPool(erc20PoolID) returns (uint256 ERC20Amount) {
        bytes32 lbtID;
        bytes32 sbtID;
        {
            (bytes32[] memory bonds, ) = _bondMakerContract.getBondGroup(bondGroupID);
            require(bonds.length == 2, "the bond group must include only 2 types of bond.");
            lbtID = bonds[1];
            sbtID = bonds[0];
        }

        (address contractAddress, uint256 maturity, , ) = _bondMakerContract.getBond(lbtID);
        require(contractAddress != address(0), "the bond is not registered");
        ERC20 bondToken = ERC20(contractAddress);

        PoolInfo memory pool = poolMap[erc20PoolID];
        require(!pool.isLBTSellPool, "This pool is not for buying LBT");

        ERC20 token = pool.ERC20Address;
        {
            uint256 rateE8 = calcRateLBT2ERC20(sbtID, erc20PoolID, maturity);
            ERC20Amount = _applyDecimalGap(LBTAmount.mul(rateE8), bondToken, token).div(1e8);
            require(ERC20Amount != 0, "must transfer non-zero token amount");
        }

        require(
            token.transferFrom(deployer[erc20PoolID], msg.sender, ERC20Amount),
            "fail to transfer ERC20 token"
        );
        require(
            bondToken.transferFrom(msg.sender, deployer[erc20PoolID], LBTAmount),
            "fail to transfer LBT"
        );

        emit LogLBTERC20TokenSwap(
            erc20PoolID,
            msg.sender,
            bondGroupID,
            address(token),
            LBTAmount,
            ERC20Amount
        );
    }

    /**
     * @notice this function is scam prevention. LBT price will not be lower than EtherPrice - StrikePrice.
     */
    function _getLowestPrice(bytes32 sbtID, uint256 etherPrice)
        internal
        view
        returns (uint256 lowestPrice, uint256 strikePrice)
    {
        (, , strikePrice, ) = _bondMakerContract.getBond(sbtID);
        require(strikePrice != 0, "Your LBT input is not recognized as LBT");
        if (etherPrice > strikePrice) {
            lowestPrice = etherPrice.sub(strikePrice);
        }
    }

    function deletePoolAndProvider(bytes32 erc20PoolID) public isExistentPool(erc20PoolID) {
        require(deployer[erc20PoolID] == msg.sender, "this pool is not owned");
        delete poolMap[erc20PoolID];
        delete oracleInfo[erc20PoolID];
    }

    /**
     * @dev Calcurate an approximate value of the square root of x by Newton's method.
     */
    function _sqrt(int256 x) internal pure returns (int256 y) {
        require(x >= 0, "cannot calculate the square root of a negative number");
        int256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /**
     * @notice Calcurate the exponent of the int256 value.
     * WARNING: 10**8 is of uint256 type, but _pow(10, 8) is of int256 type.
     * @dev If y is zero, z is 1 whatever x is.
     */
    function _pow(int256 x, uint256 y) internal pure returns (int256 z) {
        z = 1;
        for (uint256 i = 0; i < y; i++) {
            z = z.mul(x);
        }
    }

    /**
     * @notice Calculate an approximate value of the logarithm of input value by
     * Taylor expansion.
     * @dev log(x + 1) = x - 1/2 x^2 + 1/3 x^3 - 1/4 x^4 + 1/5 x^5
     *                     - 1/6 x^6 + 1/7 x^7 - 1/8 x^8 + ...
     */
    function _logTaylor(int256 inputE4) internal pure returns (int256 outputE4) {
        outputE4 = 0;
        int256 sign;
        require(inputE4 < 2 * 10**4, "inputE4 < 20000 (2) is required");
        for (uint256 i = 1; i < 9; i++) {
            if (i % 2 == 0) {
                sign = -1;
            } else {
                sign = 1;
            }
            outputE4 = outputE4.add(
                _pow(inputE4, i).div(_pow(10, 4 * i - 4)).div(int256(i)).mul(sign)
            );
        }
    }

    /**
     * @notice Calculate the cumulative distribution function of standard normal
     * distribution by Taylor expansion.
     * @dev N(x)
     *    = exp(-(x^2)/2) / sqrt(2*PI)
     *    = 1/2 + (x - 1/6 x^3 + 1/40 x^5 - 1/330 x^7 + 3456 x^9 - ...)/sqrt(2*PI)
     */
    function _NTaylor(int256 inputE4) internal pure returns (int256 outputE4) {
        int256 t = inputE4
            .sub(_pow(inputE4, 3).div(6 * 10**8))
            .add(_pow(inputE4, 5).div(40 * 10**16))
            .sub(_pow(inputE4, 7).div(330 * 10**24))
            .add(_pow(inputE4, 9).div(3456 * 10**32));
        return t.mul(10**8).div(SQRT_2PI_E8).add(5 * 10**3);
    }

    function _calcNd1(
        int256 spotPerStrikeE4,
        int256 volatilityE8,
        int256 untilMaturity
    ) internal pure returns (int256 nd1E4) {
        int256 logSigE4 = _logTaylor(spotPerStrikeE4.sub(10**4));
        int256 sigE8 = volatilityE8.mul(_sqrt(untilMaturity)).mul(10**8).div(SQRT_YEAR_E8);
        int256 d1E4 = logSigE4.mul(10**8).div(sigE8).add(sigE8.div(2 * 10**4));
        return _NTaylor(d1E4);
    }

    function _calcLbtLeverage(
        uint256 etherPriceE4,
        uint256 lbtPriceE4,
        int256 nd1E4
    ) internal pure returns (uint256 lbtLeverageE4) {
        int256 modifiedNd1E4 = nd1E4 < MIN_ND1 ? MIN_ND1 : nd1E4 > MAX_ND1 ? MAX_ND1 : nd1E4;
        return
            lbtPriceE4 != 0
                ? modifiedNd1E4.toUint256().mul(etherPriceE4).div(lbtPriceE4)
                : 100 * 10**4;
    }

    function calcLbtLeverage(
        uint256 etherPriceE4,
        uint256 strikePriceE4,
        uint256 ethVolatilityE8,
        uint256 untilMaturity,
        uint256 lbtPriceE4
    ) public pure returns (uint256 lbtLeverageE4) {
        uint256 spotPerStrikeE4 = etherPriceE4.mul(10**4).div(
            strikePriceE4,
            "strike price must be non-zero"
        );

        /// @dev cannot calculate nd1 when pricePerStrikeE4 >= 20000
        int256 nd1E4 = MAX_ND1;
        if (spotPerStrikeE4 < 2 * 10**4) {
            nd1E4 = _calcNd1(
                spotPerStrikeE4.toInt256(),
                ethVolatilityE8.toInt256(),
                untilMaturity.toInt256()
            );
        }

        return lbtLeverageE4 = _calcLbtLeverage(etherPriceE4, lbtPriceE4, nd1E4);
    }
}
