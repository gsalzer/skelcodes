pragma solidity ^0.6.2;


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


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


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


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}


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


/**
 * @title Primitive's Contract Interfaces
 * @author Primitive
 */

interface IPrime {
    function balanceOf(address user) external view returns (uint);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function swap(address receiver) external returns (
        uint256 inTokenS,
        uint256 inTokenP,
        uint256 outTokenU
    );
    function mint(address receiver) external returns (
        uint256 inTokenU,
        uint256 outTokenR
    );
    function redeem(address receiver) external returns (
        uint256 inTokenR
    );
    function close(address receiver) external returns (
        uint256 inTokenR,
        uint256 inTokenP,
        uint256 outTokenU
    );

    function tokenR() external view returns (address);
    function tokenS() external view returns (address);
    function tokenU() external view returns (address);
    function base() external view returns (uint256);
    function price() external view returns (uint256);
    function expiry() external view returns (uint256);
    function cacheU() external view returns (uint256);
    function cacheS() external view returns (uint256);
    function factory() external view returns (address);
    function marketId() external view returns (uint256);
    function maxDraw() external view returns (uint256 draw);
    function getCaches() external view returns (uint256 _cacheU, uint256 _cacheS);
    function getTokens() external view returns (address _tokenU, address _tokenS, address _tokenR);
    function prime() external view returns (
            address _tokenS,
            address _tokenU,
            address _tokenR,
            uint256 _base,
            uint256 _price,
            uint256 _expiry
    );
}

interface IPrimeTrader {
    function safeRedeem(address tokenP, uint256 amount, address receiver) external returns (
        uint256 inTokenR
    );
    function safeSwap(address tokenP, uint256 amount, address receiver) external returns (
        uint256 inTokenS,
        uint256 inTokenP,
        uint256 outTokenU
    );
    function safeMint(address tokenP, uint256 amount, address receiver) external returns (
        uint256 inTokenU,
        uint256 outTokenR
    );
    function safeClose(address tokenP, uint256 amount, address receiver) external returns (
        uint256 inTokenR,
        uint256 inTokenP,
        uint256 outTokenU
    );
}

interface IPrimeRedeem {
    function balanceOf(address user) external view returns (uint);
    function mint(address user, uint256 amount) external payable returns (bool);
    function burn(address user, uint256 amount) external payable returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


/**
 * @title Primitive's Instruments
 * @author Primitive
 */
library Instruments {
    struct PrimeOption {
        address tokenU;
        address tokenS;
        uint256 base;
        uint256 price;
        uint256 expiry;
    }
}


/**
 * @title   ERC-20 Binary Option Primitive
 * @author  Primitive
 */


contract PrimeOption is ERC20, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    address public tokenR;
    address public factory;

    uint256 public cacheU;
    uint256 public cacheS;
    uint256 public cacheR;

    uint256 public marketId;

    Instruments.PrimeOption public option;

    event Mint(address indexed from, uint256 outTokenP, uint256 outTokenR);
    event Swap(address indexed from, uint256 outTokenU, uint256 inTokenS);
    event Redeem(address indexed from, uint256 inTokenR);
    event Close(address indexed from, uint256 inTokenP);
    event Fund(uint256 cacheU, uint256 cacheS, uint256 cacheR);

    constructor (
        string memory name,
        string memory symbol,
        uint256 _marketId,
        address tokenU,
        address tokenS,
        uint256 base,
        uint256 price,
        uint256 expiry
    )
        public
        ERC20(name, symbol)
    {
        require(tokenU != address(this) && tokenS != address(this), "ERR_SELF");
        marketId = _marketId;
        factory = msg.sender;
        option = Instruments.PrimeOption(
            tokenU,
            tokenS,
            base,
            price,
            expiry
        );
    }

    modifier notExpired {
        require(option.expiry >= block.timestamp, "ERR_EXPIRED");
        _;
    }

    // Called by factory on deployment once.
    function initTokenR(address _tokenR) public returns (bool) {
        require(msg.sender == factory, "ERR_NOT_OWNER");
        tokenR = _tokenR;
        return true;
    }

    function kill() public {
        require(msg.sender == factory, "ERR_NOT_OWNER");
        if(paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    /* =========== CACHE & TOKEN GETTER FUNCTIONS =========== */


    function getCaches() public view returns (uint256 _cacheU, uint256 _cacheS, uint256 _cacheR) {
        _cacheU = cacheU;
        _cacheS = cacheS;
        _cacheR = cacheR;
    }

    function getTokens() public view returns (address _tokenU, address _tokenS, address _tokenR) {
        _tokenU = option.tokenU;
        _tokenS = option.tokenS;
        _tokenR = tokenR;
    }


    /* =========== ACCOUNTING FUNCTIONS =========== */


    /**
     * @dev Updates the cached balances to the actual current balances.
     */
    function update() external nonReentrant {
        _fund(
            IERC20(option.tokenU).balanceOf(address(this)),
            IERC20(option.tokenS).balanceOf(address(this)),
            IERC20(tokenR).balanceOf(address(this))
        );
    }

    /**
     * @dev Difference between balances and caches is sent out so balances == caches.
     * Fixes tokenU, tokenS, tokenR, and tokenP.
     */
    function take() external nonReentrant {
        (
            address _tokenU,
            address _tokenS,
            address _tokenR
        ) = getTokens();
        IERC20(_tokenU).transfer(msg.sender,
            IERC20(_tokenU).balanceOf(address(this))
                .sub(cacheU)
        );
        IERC20(_tokenS).transfer(msg.sender,
            IERC20(_tokenS).balanceOf(address(this))
                .sub(cacheS)
        );
        IERC20(_tokenR).transfer(msg.sender,
            IERC20(_tokenR).balanceOf(address(this))
                .sub(cacheR)
        );
        IERC20(address(this)).transfer(msg.sender,
            IERC20(address(this)).balanceOf(address(this))
        );
    }

    /**
     * @dev Sets the cache balances to new values.
     */
    function _fund(uint256 balanceU, uint256 balanceS, uint256 balanceR) private {
        cacheU = balanceU;
        cacheS = balanceS;
        cacheR = balanceR;
        emit Fund(balanceU, balanceS, balanceR);
    }


    /* =========== CRITICAL STATE MUTABLE FUNCTIONS =========== */


    /**
     * @dev Core function to mint new Prime ERC-20 Options.
     * @notice inTokenU = outTokenP, inTokenU * ratio = outTokenR
     * Checks the balance of the contract against the token's 'cache',
     * The difference is the amount of tokenU sent into the contract.
     * The difference determines how many Primes and Redeems to mint.
     * Only callable when the option is not expired.
     * @param receiver The newly minted tokens are sent to the receiver address.
     */
    function mint(address receiver)
        external
        nonReentrant
        notExpired
        whenNotPaused
        returns (uint256 inTokenU, uint256 outTokenR)
    {
        // Current balance of tokenU.
        uint256 balanceU = IERC20(option.tokenU).balanceOf(address(this));

        // Mint inTokenU equal to the difference between current balance and previous balance of tokenU.
        inTokenU = balanceU.sub(cacheU);

        // Make sure outToken is not 0.
        require(inTokenU.mul(option.price) > 0, "ERR_ZERO");

        // Mint outTokenR equal to tokenU * ratio FIX - FURTHER CHECKS
        outTokenR = inTokenU.mul(option.price).div(option.base);

        // Mint the tokens.
        require(IPrimeRedeem(tokenR).mint(receiver, outTokenR), "ERR_BURN_FAIL");
        _mint(receiver, inTokenU);

        // Update the caches.
        _fund(balanceU, cacheS, cacheR);
        emit Mint(receiver, inTokenU, outTokenR);
    }

    /**
     * @dev Swap tokenS to tokenU at a rate of tokenS / ratio = tokenU.
     * @notice inTokenS / ratio = outTokenU && inTokenP >= outTokenU
     * Checks the balance against the previously cached balance.
     * The difference is the amount of tokenS sent into the contract.
     * The difference determines how much tokenU to send out.
     * Only callable when the option is not expired.
     * @param receiver The outTokenU is sent to the receiver address.
     */
    function swap(
        address receiver
    )
        external
        nonReentrant
        notExpired
        whenNotPaused
        returns (uint256 inTokenS, uint256 inTokenP, uint256 outTokenU)
    {
        // Stores addresses locally for gas savings.
        address _tokenU = option.tokenU;
        address _tokenS = option.tokenS;

        // Current balances.
        uint256 balanceS = IERC20(_tokenS).balanceOf(address(this));
        uint256 balanceU = IERC20(_tokenU).balanceOf(address(this));
        uint256 balanceP = balanceOf(address(this));

        // Differences between tokenS balance less cache.
        inTokenS = balanceS.sub(cacheS);

        // Assumes the cached balance is 0.
        // This is because the close function burns the Primes received.
        // Only external transfers will be able to send Primes to this contract.
        // Close() and swap() are the only function that check for the Primes balance.
        inTokenP = balanceP;

        // inTokenS / ratio = outTokenU
        outTokenU = inTokenS.mul(option.base).div(option.price); // FIX

        require(inTokenS > 0 && inTokenP > 0, "ERR_ZERO");
        require(
            inTokenP >= outTokenU &&
            balanceU >= outTokenU,
            "ERR_BAL_UNDERLYING"
        );

        // Burn the Prime options at a 1:1 ratio to outTokenU.
        _burn(address(this), inTokenP);

        // Transfer the swapped tokenU to receiver.
        require(
            IERC20(_tokenU).transfer(receiver, outTokenU),
            "ERR_TRANSFER_OUT_FAIL"
        );

        // Current balances.
        balanceS = IERC20(_tokenS).balanceOf(address(this));
        balanceU = IERC20(_tokenU).balanceOf(address(this));

        // Update the cached balances.
        _fund(balanceU, balanceS, cacheR);
        emit Swap(receiver, outTokenU, inTokenS);
    }

    /**
     * @dev Burns tokenR to withdraw tokenS at a ratio of 1:1.
     * @notice inTokenR = outTokenS
     * Should only be called by a contract that checks the balanaces to be sent correctly.
     * Checks the tokenR balance against the previously cached tokenR balance.
     * The difference is the amount of tokenR sent into the contract.
     * The difference is equal to the amount of tokenS sent out.
     * Callable even when expired.
     * @param receiver The inTokenR quantity of tokenS is sent to the receiver address.
     */
    function redeem(address receiver) external nonReentrant returns (uint256 inTokenR) {
        address _tokenS = option.tokenS;
        address _tokenR = tokenR;

        // Current balances.
        uint256 balanceS = IERC20(_tokenS).balanceOf(address(this));
        uint256 balanceR = IERC20(_tokenR).balanceOf(address(this));

        // Difference between tokenR balance and cache.
        inTokenR = balanceR.sub(cacheR);
        verifyBalance(balanceS, inTokenR, "ERR_BAL_STRIKE");

        // Burn tokenR in the contract. Send tokenS to msg.sender.
        require(
            IPrimeRedeem(_tokenR).burn(address(this), inTokenR) &&
            IERC20(_tokenS).transfer(receiver, inTokenR),
            "ERR_TRANSFER_OUT_FAIL"
        );

        // Current balances.
        balanceS = IERC20(_tokenS).balanceOf(address(this));
        balanceR = IERC20(_tokenR).balanceOf(address(this));

        // Update the cached balances.
        _fund(cacheU, balanceS, balanceR);
        emit Redeem(receiver, inTokenR);
    }

    /**
     * @dev Burn Prime and Prime Redeem tokens to withdraw tokenU.
     * @notice inTokenR / ratio = outTokenU && inTokenP >= outTokenU
     * Checks the balances against the previously cached balances.
     * The difference between the tokenR balance and cache is the inTokenR.
     * The balance of tokenP is equal to the inTokenP.
     * The outTokenU is equal to the inTokenR / ratio.
     * The contract requires the inTokenP >= outTokenU and the balanceU >= outTokenU.
     * The contract burns the inTokenR and inTokenP amounts.
     * @param receiver The outTokenU is sent to the receiver address.
     */
    function close(address receiver)
        external
        nonReentrant
        returns (uint256 inTokenR, uint256 inTokenP, uint256 outTokenU)
    {
        // Stores addresses locally for gas savings.
        address _tokenU = option.tokenU;
        address _tokenR = tokenR;

        // Current balances.
        uint256 balanceU = IERC20(_tokenU).balanceOf(address(this));
        uint256 balanceR = IPrimeRedeem(_tokenR).balanceOf(address(this));
        uint256 balanceP = balanceOf(address(this));

        // Differences between current and cached balances.
        inTokenR = balanceR.sub(cacheR);

        // The quantity of tokenU to send out it still determined by the amount of inTokenR.
        // This outTokenU amount is checked against inTokenP.
        // inTokenP must be greater than or equal to outTokenU.
        // balanceP must be greater than or equal to outTokenU.
        // Neither inTokenR or inTokenP can be zero.
        outTokenU = inTokenR.mul(option.base).div(option.price);

        // Assumes the cached balance is 0.
        // This is because the close function burns the Primes received.
        // Only external transfers will be able to send Primes to this contract.
        // Close() and swap() are the only function that check for the Primes balance.
        // If option is expired, tokenP does not need to be sent in. Only tokenR.
        inTokenP = option.expiry > block.timestamp ? balanceP : outTokenU;

        require(inTokenR > 0 && inTokenP > 0, "ERR_ZERO");
        require(inTokenP >= outTokenU && balanceU >= outTokenU, "ERR_BAL_UNDERLYING");

        // Burn inTokenR and inTokenP.
        if(option.expiry > block.timestamp) {
            _burn(address(this), inTokenP);
        }

        // Send outTokenU to user.
        // User does not receive extra tokenU if there was extra tokenP in the contract.
        // User receives outTokenU proportional to inTokenR.
        // Amount of inTokenP must be greater than outTokenU.
        // If tokenP was sent to the contract from an external call,
        // a user could send only tokenR and receive the proportional amount of tokenU,
        // as long as the amount of outTokenU is less than or equal to
        // the balance of tokenU and tokenP.
        require(
            IPrimeRedeem(_tokenR).burn(address(this), inTokenR) &&
            IERC20(_tokenU).transfer(receiver, outTokenU),
            "ERR_TRANSFER_OUT_FAIL"
        );

        // Current balances of tokenU and tokenR.
        balanceU = IERC20(_tokenU).balanceOf(address(this));
        balanceR = IPrimeRedeem(_tokenR).balanceOf(address(this));

        // Update the cached balances.
        _fund(balanceU, cacheS, balanceR);
        emit Close(receiver, outTokenU);
    }


    /* =========== UTILITY =========== */


    function tokenS() public view returns (address) {
        return option.tokenS;
    }

    function tokenU() public view returns (address) {
        return option.tokenU;
    }

    function base() public view returns (uint256) {
        return option.base;
    }
    function price() public view returns (uint256) {
        return option.price;
    }

    function expiry() public view returns (uint256) {
        return option.expiry;
    }

    function prime() public view returns (
            address _tokenU,
            address _tokenS,
            address _tokenR,
            uint256 _base,
            uint256 _price,
            uint256 _expiry
        )
    {
        Instruments.PrimeOption memory _prime = option;
        _tokenU = _prime.tokenU;
        _tokenS = _prime.tokenS;
        _tokenR = tokenR;
        _base = _prime.base;
        _price = _prime.price;
        _expiry = _prime.expiry;
    }

    /**
     * @dev Utility function to get the max withdrawable tokenS amount of msg.sender.
     */
    function maxDraw() public view returns (uint256 draw) {
        uint256 balanceR = IPrimeRedeem(tokenR).balanceOf(msg.sender);
        cacheS > balanceR ?
            draw = balanceR :
            draw = cacheS;
    }

    /**
     * @dev Utility function to check if balance is >= minBalance.
     */
    function verifyBalance(
        uint256 balance,
        uint256 minBalance,
        string memory errorCode
    ) internal pure {
        minBalance == 0 ?
            require(balance > minBalance, errorCode) :
            require(balance >= minBalance, errorCode);
    }
}
