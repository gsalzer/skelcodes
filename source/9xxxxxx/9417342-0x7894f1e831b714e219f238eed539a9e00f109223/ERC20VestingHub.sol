// File: openzeppelin-solidity/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
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
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

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
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

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
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

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
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

// File: openzeppelin-solidity/contracts/utils/Address.sol

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/VestingHub.sol

pragma solidity ^0.5.0;



/**
 * @dev VestingHub common features: single/multiple vestings per account, linear/step claim
 */
contract VestingHub is Ownable {
    using SafeMath for uint256;
    struct Vesting {
        address creator;
        address beneficiary;
        uint256 initialAmount;
        uint256 remainingAmount;
        uint256 born;
        uint256 duration;
        uint256 lastAccess;
        bytes32 label;
        bool linearClaim;
        bool closed;
    }

    mapping(uint256 => Vesting) internal vestings;
    mapping(address => bool) internal hasVesting;

    // VestingHub with variable amount (fixedAmount = 0) or fixed one (fixedAmount != 0)
    uint256 public fixedAmount;

    // VestingHub with variable duration (fixedDuration = 0) or fixed one (fixedDuration != 0)
    uint256 public fixedDuration;

    // The VestingHub is closed; All vestings can be claimed
    bool public closed;

    // The VestingHub is paused
    bool public paused;

    // The VestingHub permit multiple investiment from the same user
    bool public multipleVestingAllowed;

    // -----------------------
    // statistical variables
    // -----------------------
    // Total amounts transferred in the VestingHub from its creation
    uint256 public totalReceivedAmount;

    // Number of created Vesting
    uint256 public vestingsCreated;

    // Number of Terminated Vesting (closed or completely claimed)
    uint256 public vestingsClosed;

    // -----------------------
    // Logs
    // -----------------------
    event LogVestingCreation(
        address indexed creator,
        uint256 indexed vestingId,
        bytes32 label,
        address indexed beneficiary,
        uint256 time,
        uint256 duration,
        uint256 amount,
        bool linearClaim
    );
    event LogVestingClaim(
        address indexed sender,
        uint256 indexed vestingId,
        address indexed beneficiary,
        uint256 time,
        uint256 claimedAmount
    );
    event LogVestingClose(
        address indexed sender,
        uint256 indexed vestingId,
        address indexed beneficiary,
        uint256 time,
        uint256 releasedAmount
    );
    event LogDurationDecrease(
        address indexed sender,
        uint256 indexed vestingId,
        uint256 time,
        uint256 duration
    );
    event LogPaused(address sender, uint256 time);
    event LogUnpaused(address sender, uint256 time);
    event LogAllClaimable(address indexed sender, uint256 time);

    modifier whenNotPaused() {
        require(!paused, "VestingHub is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "VestingHub is not paused");
        _;
    }


    constructor(uint256 _fixedAmount, uint256 _fixedDuration, bool _multipleVestingAllowed) internal {
        fixedAmount = _fixedAmount;
        fixedDuration = _fixedDuration;
        multipleVestingAllowed = _multipleVestingAllowed;
    }

    /**
     * @dev returns the claimableAmount available
     * @return claimableAmount value
     * @return ended flag indicating the vesting is closed
     */
    function getClaimableAmount(Vesting storage vesting) internal view returns (uint256 claimableAmount, bool ended) {
        ended = now >= vesting.born.add(vesting.duration) || closed;
        if (ended == false) {
            if (vesting.linearClaim == false) {
                claimableAmount = 0;
            }
            else {
                claimableAmount = vesting.initialAmount.div(vesting.duration).mul(block.timestamp.sub(vesting.lastAccess));
            }
        } else {
            claimableAmount = vesting.remainingAmount;
        }
    }

    /**
     * @dev pause the HUB
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit LogPaused(msg.sender, now);
    }

    /**
     * @dev unpause the HUB
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit LogUnpaused(msg.sender, now);
    }

    /**
     * @dev Create a new vestingID
     * @param nonce the user nonce
     * @return the vesting unique identifier
     */
    function newVestingId(uint256 nonce) public view returns (uint256 id) {
        id = uint256(keccak256(abi.encode(address(this), msg.sender, block.number, nonce)));
    }

    /**
     * @dev Return the information associated to the specified vesting.
     * @param _id the vesting unique identifier
     */
    function getVesting(uint256 _id)
        public
        view
        returns (
            bytes32 label,
            address creator,
            address beneficiary,
            uint256 initialAmount,
            uint256 remainingAmount,
            uint256 claimableAmount,
            uint256 born,
            uint256 duration,
            uint256 lastAccess,
            bool linearClaim,
            bool isClosed)
    {
        bool ended;
        Vesting storage vesting = vestings[_id];
        (claimableAmount, ended) = getClaimableAmount(vesting);
        return (
            vesting.label,
            vesting.creator,
            vesting.beneficiary,
            vesting.initialAmount,
            vesting.remainingAmount,
            claimableAmount,
            vesting.born,
            vesting.duration,
            vesting.lastAccess,
            vesting.linearClaim,
            vesting.closed
        );
    }

    /**
     * @dev Create a new vesting for transaction sender.
     * @param _id the vesting unique identifier
     * @param _label the vesting label assigned to the vesting
     * @param _beneficiary the vesting beneficiary
     * @param _amount the vesting amounts
     * @param _duration the vesting duration
     * @param _linearClaim the claim type
     */
    function create(
        uint256 _id,
        bytes32 _label,
        address _beneficiary,
        uint256 _amount,
        uint256 _duration,
        bool _linearClaim
    ) internal whenNotPaused {

        require(_beneficiary != address(0), "beneficiary is 0");
        require(vestings[_id].beneficiary == address(0), "vesting ID already used");
        require((fixedAmount == 0 && _amount != 0) || (_amount != 0 && _amount == fixedAmount), "vesting amount not valid");
        require((fixedDuration == 0 && _duration != 0) || (_duration != 0 && _duration == fixedDuration), "vesting duration not valid");
        require(closed == false, "vesting hub is no more active");
        require(multipleVestingAllowed || !hasVesting[msg.sender], "vesting already present");

        Vesting memory vesting = Vesting({
            creator: msg.sender,
            beneficiary: _beneficiary,
            label: _label,
            initialAmount: _amount,
            remainingAmount: _amount,
            born: now,
            duration: _duration,
            lastAccess: now,
            closed: false,
            linearClaim: _linearClaim
        });
        vestings[_id] = vesting;

        if (!multipleVestingAllowed) {
            hasVesting[msg.sender] = true;
        }
        totalReceivedAmount = totalReceivedAmount.add(_amount);
        vestingsCreated = vestingsCreated.add(1);
    }

    /*
     * @dev Let the vesting beneficiary receive the claimable amount.
     * @param vesting the vesting to claim
     * @return claimableAmount the amount that the beneficiary can claim
     * @return beneficiary the beneficiary of the vesting
     */
    function claim(Vesting storage vesting)
        internal
        returns (uint256 claimableAmount, address beneficiary)
    {
        bool ended;
        beneficiary = vesting.beneficiary;
        address creator = vesting.creator;

        require(beneficiary == msg.sender || creator == msg.sender, "caller is not the beneficiary or vesting creator");
        require(vesting.remainingAmount > 0, "vesting already claimed");

        (claimableAmount, ended) = getClaimableAmount(vesting);

        if (ended)
        {
            vesting.remainingAmount = 0;
            vestingsClosed = vestingsClosed.add(1);
            if (!multipleVestingAllowed) {
                hasVesting[creator] = false;
            }
        } else {
            require(vesting.linearClaim, "vesting claim is not linear");
            require(claimableAmount > 0, "no amount to claim");

            vesting.remainingAmount = vesting.remainingAmount.sub(claimableAmount);
        }
        vesting.lastAccess = block.timestamp;
    }

    /*
     * @dev Force the transfer of the remaining vesting amount still claimable.
     * @param vesting struct
     * @return claimableAmount the amount that the beneficiary will receive
     * @return beneficiary the beneficiary of the vesting
     */
    function close(Vesting storage vesting)
        internal
        returns (uint256 claimableAmount, address beneficiary)
    {
        address creator = vesting.creator;
        require(creator == msg.sender, "caller is not vesting owner");

        beneficiary = vesting.beneficiary;
        claimableAmount = vesting.remainingAmount;
        require(claimableAmount > 0, "no amount to claim");

        vesting.remainingAmount = 0;
        vesting.lastAccess = block.timestamp;
        vesting.closed = true;
        vestingsClosed = vestingsClosed.add(1);

        if (!multipleVestingAllowed) {
            hasVesting[creator] = false;
        }
    }

    /**
     * @dev Decrease the duration of HUB or specific vesting
     * @param _id the vesting unique identifier (if fixedDuration != 0 -> _id could be zero)
     * @param _duration the new vesting duration
     */
    function decreaseDurationTo(uint256 _id, uint256 _duration)
        public
        returns (bool success)
    {
        if (fixedDuration != 0) {
            require(msg.sender == owner(), "caller is not HUB owner");
            require((_duration < fixedDuration) && (_duration > 0), "invalid new fixed duration");
            fixedDuration = _duration;
        }
        else {
            Vesting storage vesting = vestings[_id];
            require(msg.sender == vesting.creator, "caller is not vesting owner");
            require(_duration < vesting.duration, "new vesting duration >= current one");
            vesting.duration = _duration;
        }
        success = true;
        emit LogDurationDecrease(msg.sender, _id, now, _duration);
    }

    /*
     * @dev Force all the vesting of the HUB as claimable
     */
    function makeAllClaimable() public onlyOwner  returns (bool success) {
        require(closed == false, "already closed");
        closed = true;
        success = true;

        emit LogAllClaimable(msg.sender, now);
    }
}

// File: contracts/ERC20VestingHub.sol

pragma solidity ^0.5.0;





/**
 * @dev ERC20VestingHub features: only ERC20 tokens, single/multiple vestings per account, linear/step claim
 */
contract ERC20VestingHub is VestingHub {
    using SafeERC20 for ERC20;
    using Address for address;

    uint256 public depositedTokens;
    ERC20 public token;

    constructor(address _token, uint256 _fixedAmount, uint256 _fixedDuration, bool _multipleVestingAllowed)
        public
        VestingHub(_fixedAmount, _fixedDuration, _multipleVestingAllowed)
    {
        require(address(_token).isContract(), "token is not a contract");

        token = ERC20(_token);

        require(token.totalSupply() >= 0, "wrong token address"); // Verify if the address is a ERC20 token
    }

    /**
    * @dev Create a new vesting for transaction sender.
    * @param _id the vesting unique identifier
    * @param _label the vesting label assigned to the vesting
    * @param _beneficiary the vesting beneficiary
    * @param _amount the vesting amount
    * @param _duration the vesting duration
    * @param _linearClaim the vesting is claimable linearly
    */
    function createVesting(
        uint256 _id,
        bytes32 _label,
        address _beneficiary,
        uint256 _amount,
        uint256 _duration,
        bool _linearClaim
    ) public {
        super.create(
               _id,
               _label,
               _beneficiary,
               _amount,
               _duration,
               _linearClaim
        );

        depositedTokens = depositedTokens.add(_amount);

        emit LogVestingCreation(
            msg.sender,
            _id,
            _label,
            _beneficiary,
            now,
            _duration,
            _amount,
            _linearClaim
        );

        token.safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
    * @dev Let the vesting owner receive the claimable amount in ERC20 tokens.
    * @param _id the vesting unique identifier
    */
    function claimVesting(uint256 _id) public returns (bool success) {
        Vesting storage vesting = vestings[_id];

        (uint256 claimableAmount, address beneficiary) = claim(vesting);

        depositedTokens = depositedTokens.sub(claimableAmount);

        emit LogVestingClaim(
            msg.sender,
            _id,
            beneficiary,
            now,
            claimableAmount
        );

        token.safeTransfer(beneficiary, claimableAmount);

        return true;
    }

    /**
    * @dev Force the transfer of the specified vesting amount still claimable.
    * @param _id the vesting unique identifier
    */
    function closeVesting(uint256 _id) public returns (bool success) {
        Vesting storage vesting = vestings[_id];

        (uint256 claimableAmount, address beneficiary) = close(vesting);

        depositedTokens = depositedTokens.sub(claimableAmount);

        emit LogVestingClose(
            msg.sender,
            _id,
            beneficiary,
            now,
            claimableAmount
        );

        token.safeTransfer(beneficiary, claimableAmount);

        return true;
    }

    /**
    * @dev reclaimToken to reclaim also exceeding vested ERC20 tokens.
    * @param _token the ERC20 token
    */
    function reclaimToken(ERC20 _token) external onlyOwner {
        require(address(_token) != address(0), "cannot reclaim invalid token");

        uint256 balance = _token.balanceOf(address(this));
        uint256 reclaimableAmount = _token == token ? balance.sub(depositedTokens) : balance;
        require(reclaimableAmount > 0, "no amount to reclaim");

        _token.safeTransfer(owner(), reclaimableAmount);
    }
}
