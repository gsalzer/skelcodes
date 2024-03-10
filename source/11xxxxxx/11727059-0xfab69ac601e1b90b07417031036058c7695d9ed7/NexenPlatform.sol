// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
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
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
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
     * Requirements:
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
     * Requirements:
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
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
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

pragma solidity >=0.6.2 <0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Ownable is Context {
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

pragma solidity ^0.7.4;

interface IPriceConsumerV3 {
    function getLatestPrice() external view returns (int);
}

interface IUniswapV2Router02 {
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);
      
    function WETH() external returns (address); 
    
    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);
}


contract NexenPlatform is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    enum RequestState {None, LenderCreated, BorrowerCreated, Cancelled, Matched, Closed, Expired, Disabled}
    enum Currency {DAI, USDT, ETH}
    
    IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    
    IPriceConsumerV3 public priceConsumerDAI;
    IPriceConsumerV3 public priceConsumerUSDT;

    IERC20 public nexenToken;
    
    ERC20 daiToken = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F); 
    ERC20 usdtToken = ERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    
    bool public paused = false;
    bool public genesisPhase = false;
    uint256 public amountToReward = 1000 * 10 ** 18;
    
    uint public lenderFee = 1; //1%
    uint public borrowerFee = 1; //1%
    
    mapping(uint256 => uint256) public interests;

    mapping(address => uint256) public depositedDAI;
    mapping(address => uint256) public depositedUSDT;
    mapping(address => uint256) public depositedWEI;
    
    uint256 public daiFees;
    uint256 public usdtFees;
    uint256 public ethFees;
    
    struct Request {
        // Internal fields
        RequestState state;
        address payable borrower;
        address payable lender;
        Currency currency;
        // Fields for both parties
        uint256 cryptoAmount;
        uint256 durationInDays;
        uint256 expireIfNotMatchedOn;
        // Fields for borrower
        uint256 ltv;
        uint256 weiAmount;
        uint256 daiVsWeiCurrentPrice;
        uint256 usdtVsWeiCurrentPrice;
        // Fields after matching
        uint256 lendingFinishesOn;
    }
    
    mapping (uint256 => Request) public requests;
    
    event OpenRequest(uint256 requestId, address indexed borrower, address indexed lender, uint256 cryptoAmount, uint256 durationInDays, uint256 expireIfNotMatchedOn, uint256 ltv, uint256 weiAmount, uint256 daiVsWeiCurrentPrice, uint256 usdtVsWeiCurrentPrice, uint256 lendingFinishesOn, RequestState state, Currency currency);
    event CollateralSold(uint256 requestId, uint256 totalCollateral, uint256 totalSold, uint256 totalDAIBought);
    event RequestMatchedBorrower(uint256 requestId, address indexed borrower, address indexed lender, uint256 cryptoAmount, uint256 weiAmount, uint256 daiVsWeiCurrentPrice, uint256 usdtVsWeiCurrentPrice);
    event RequestMatchedLender(uint256 requestId, address indexed borrower, address indexed lender, uint256 cryptoAmount);
    event RequestCancelled(uint256 requestId, address indexed borrower, address indexed lender, RequestState state, uint256 weiAmount, uint256 cryptoAmount);
    event RequestFinishedForLender(uint256 requestId, address indexed lender, uint256 daiToTransfer, uint256 totalLenderFee);
    event RequestFinishedForBorrower(uint256 requestId, address indexed borrower, uint256 daiToTransfer, uint256 weiAmount, uint256 totalBorrowerFee);
    event CollateralSoldBorrower(uint256 requestId, address indexed borrower, uint256 weiAmount, uint256 amountSold, uint256 daiToTransfer, uint256 weiRecovered, uint256 totalBorrowerFee);
    event CollateralSoldLender(uint256 requestId, address indexed lender, uint256 weiAmount, uint256 amountSold, uint256 daiToTransfer, uint256 daiRecovered, uint256 totalLenderFee);
    event CoinDeposited(address indexed caller, uint256 value, Currency currency);
    event CoinWithdrawn(address indexed caller, uint256 value, Currency currency);

    receive() external payable {
        
    }

    constructor(IPriceConsumerV3 _priceConsumerDAI, IPriceConsumerV3 _priceConsumerUSDT) {
        priceConsumerDAI = _priceConsumerDAI;
        priceConsumerUSDT = _priceConsumerUSDT;
        
        interests[20] = 4;
        interests[40] = 6;
        interests[60] = 8;
    }
    
    function createRequest(bool lend, uint256 cryptoAmount, uint256 durationInDays, uint256 expireIfNotMatchedOn, uint256 ltv, Currency currency) public payable {
        require(currency == Currency.USDT || currency == Currency.DAI, "Invalid currency");
        require(expireIfNotMatchedOn > block.timestamp, "Invalid expiration date");
        require(!paused, "The contract is paused");

        if (currency == Currency.USDT) {
            require(cryptoAmount >= 100 * 10 ** 6, "Minimum amount is 100 USDT");
        } else {
            require(cryptoAmount >= 100 * 10 ** 18, "Minimum amount is 100 DAI");
        }
        
        Request memory r;
        (r.cryptoAmount, r.durationInDays, r.expireIfNotMatchedOn, r.currency) = (cryptoAmount, durationInDays, expireIfNotMatchedOn, currency);
        
        if (lend) {
            r.lender = msg.sender;
            r.state = RequestState.LenderCreated;
            
            if (currency == Currency.USDT) {
                require(depositedUSDT[msg.sender] >= r.cryptoAmount, "Not enough USDT deposited");
                depositedUSDT[msg.sender] -= r.cryptoAmount;
            } else {
                require(depositedDAI[msg.sender] >= r.cryptoAmount, "Not enough DAI deposited");
                depositedDAI[msg.sender] -= r.cryptoAmount;
            }
        } else {
            require(interests[ltv] > 0, 'Invalid LTV');
            
            r.borrower = msg.sender;
            r.state = RequestState.BorrowerCreated;
            r.ltv = ltv;
            
            if (currency == Currency.USDT) {
                r.usdtVsWeiCurrentPrice = uint256(priceConsumerUSDT.getLatestPrice());
                r.weiAmount = calculateWeiAmountForUSDT(r.cryptoAmount, ltv, r.usdtVsWeiCurrentPrice);
            } else {
                r.daiVsWeiCurrentPrice = uint256(priceConsumerDAI.getLatestPrice());
                r.weiAmount = calculateWeiAmountForDAI(r.cryptoAmount, ltv, r.daiVsWeiCurrentPrice);
            }

            //We take the payment from the msg.value or from the deposited WEI
            if (msg.value > r.weiAmount) {
                msg.sender.transfer(msg.value - r.weiAmount);
            }
            else if (msg.value < r.weiAmount) {
                require(depositedWEI[msg.sender] > (r.weiAmount - msg.value), "Not enough ETH deposited");
                depositedWEI[msg.sender] = depositedWEI[msg.sender] - r.weiAmount + msg.value;
            }
        }

        uint256 requestId = uint256(keccak256(abi.encodePacked(r.borrower, r.lender, r.cryptoAmount, r.durationInDays, r.expireIfNotMatchedOn, r.ltv, r.currency)));
        
        require(requests[requestId].state == RequestState.None, 'Request already exists');
        
        requests[requestId] = r;

        emit OpenRequest(requestId, r.borrower, r.lender, r.cryptoAmount, r.durationInDays, r.expireIfNotMatchedOn, r.ltv, r.weiAmount, r.daiVsWeiCurrentPrice, r.usdtVsWeiCurrentPrice, r.lendingFinishesOn, r.state, r.currency);
    }
    
    function matchRequestAsLender(uint256 requestId) public {
        Request storage r = requests[requestId];
        require(r.state == RequestState.BorrowerCreated, 'Invalid request');
        require(r.expireIfNotMatchedOn > block.timestamp, 'Request expired');
        require(r.borrower != msg.sender, 'You cannot match yourself');

        r.lender = msg.sender;
        r.lendingFinishesOn = getExpirationAfter(r.durationInDays);
        r.state = RequestState.Matched;
        
        if (r.currency == Currency.DAI) {
            require(depositedDAI[msg.sender] >= r.cryptoAmount, "Not enough DAI deposited");
            depositedDAI[msg.sender] = depositedDAI[msg.sender].sub(r.cryptoAmount);
            depositedDAI[r.borrower] = depositedDAI[r.borrower].add(r.cryptoAmount);
        } else {
            require(depositedUSDT[msg.sender] >= r.cryptoAmount, "Not enough USDT deposited");
            depositedUSDT[msg.sender] = depositedUSDT[msg.sender].sub(r.cryptoAmount);
            depositedUSDT[r.borrower] = depositedUSDT[r.borrower].add(r.cryptoAmount);
        }
        
        if (genesisPhase) {
            require(nexenToken.transfer(msg.sender, amountToReward), 'Could not transfer tokens');
            require(nexenToken.transfer(r.borrower, amountToReward), 'Could not transfer tokens');
        }
        
        emit RequestMatchedLender(requestId, r.borrower, r.lender, r.cryptoAmount);
    }
    
    function matchRequestAsBorrower(uint256 requestId, uint256 ltv) public {
        Request storage r = requests[requestId];
        require(r.state == RequestState.LenderCreated, 'Invalid request');
        require(r.expireIfNotMatchedOn > block.timestamp, 'Request expired');
        require(r.lender != msg.sender, 'You cannot match yourself');

        r.borrower = msg.sender;
        r.lendingFinishesOn = getExpirationAfter(r.durationInDays);
        r.state = RequestState.Matched;
        
        r.ltv = ltv;
        
        if (r.currency == Currency.DAI) {
            r.daiVsWeiCurrentPrice = uint256(priceConsumerDAI.getLatestPrice());
            r.weiAmount = calculateWeiAmountForDAI(r.cryptoAmount, r.ltv, r.daiVsWeiCurrentPrice);
            depositedDAI[r.borrower] = depositedDAI[r.borrower].add(r.cryptoAmount);
        } else {
            r.usdtVsWeiCurrentPrice = uint256(priceConsumerUSDT.getLatestPrice());
            r.weiAmount = calculateWeiAmountForUSDT(r.cryptoAmount, r.ltv, r.usdtVsWeiCurrentPrice);
            depositedUSDT[r.borrower] = depositedUSDT[r.borrower].add(r.cryptoAmount);
        }
        
        require(depositedWEI[msg.sender] > r.weiAmount, "Not enough WEI");
        depositedWEI[msg.sender] = depositedWEI[msg.sender].sub(r.weiAmount);

        if (genesisPhase) {
            require(nexenToken.transfer(msg.sender, amountToReward), 'Could not transfer tokens');
            require(nexenToken.transfer(r.lender, amountToReward), 'Could not transfer tokens');
        }

        emit RequestMatchedBorrower(requestId, r.borrower, r.lender, r.cryptoAmount, r.weiAmount, r.daiVsWeiCurrentPrice, r.usdtVsWeiCurrentPrice);
    }
    
    function cancelRequest(uint256 requestId) public {
        Request storage r = requests[requestId];
        require(r.state == RequestState.BorrowerCreated || r.state == RequestState.LenderCreated);
        
        r.state = RequestState.Cancelled;

        if (msg.sender == r.borrower) {
            depositedWEI[msg.sender] += r.weiAmount;
        } else if (msg.sender == r.lender) {
            if (r.currency == Currency.DAI) {
                depositedDAI[msg.sender] += r.cryptoAmount;
            } else {
                depositedUSDT[msg.sender] += r.cryptoAmount;
            }
        } else {
            revert();
        }

        emit RequestCancelled(requestId, r.borrower, r.lender, r.state, r.weiAmount, r.cryptoAmount);
    }
    
    function finishRequest(uint256 _requestId) public {
        Request storage r = requests[_requestId];
        require(r.state == RequestState.Matched, "State needs to be Matched");
        
        require(msg.sender == r.borrower, 'Only borrower can call this');

        r.state = RequestState.Closed;
        
        uint256 cryptoToTransfer = getInterest(r.ltv, r.cryptoAmount).add(r.cryptoAmount);
        
        uint256 totalLenderFee = computeLenderFee(r.cryptoAmount);
        uint256 totalBorrowerFee = computeBorrowerFee(r.weiAmount);
        ethFees = ethFees.add(totalBorrowerFee);

        if (r.currency == Currency.DAI) {
            require(depositedDAI[r.borrower] >= cryptoToTransfer, "Not enough DAI deposited");
            daiFees = daiFees.add(totalLenderFee);
            depositedDAI[r.lender] += cryptoToTransfer.sub(totalLenderFee);
            depositedDAI[r.borrower] -= cryptoToTransfer;
        } else {
            require(depositedUSDT[r.borrower] >= cryptoToTransfer, "Not enough USDT deposited");
            usdtFees = daiFees.add(totalLenderFee);
            depositedUSDT[r.lender] += cryptoToTransfer.sub(totalLenderFee);
            depositedUSDT[r.borrower] -= cryptoToTransfer;
        }

        depositedWEI[r.borrower] += r.weiAmount.sub(totalBorrowerFee);
        
        emit RequestFinishedForLender(_requestId, r.lender, cryptoToTransfer.sub(totalLenderFee), totalLenderFee);
        emit RequestFinishedForBorrower(_requestId, r.borrower, cryptoToTransfer, r.weiAmount.sub(totalBorrowerFee), totalBorrowerFee);
    }
    
    function expireNonFullfiledRequest(uint256 _requestId) public {
        Request storage r = requests[_requestId];

        require(r.state == RequestState.Matched, "State needs to be Matched");
        require(msg.sender == r.lender, "Only lender can call this");
        require(block.timestamp > r.lendingFinishesOn, "Request not finished yet");
        
        r.state = RequestState.Expired;
        
        burnCollateral(_requestId, r);
    }
    
    function burnCollateral(uint256 _requestId, Request storage r) internal {
        //Minimum that we should get according to Chainlink
        //r.weiAmount.div(daiVsWeiCurrentPrice);

        //But we will use as minimum the amount we need to return to the Borrower
        uint256 cryptoToTransfer = getInterest(r.ltv, r.cryptoAmount).add(r.cryptoAmount);
        
        uint256[] memory amounts = sellCollateralInUniswap(cryptoToTransfer, r.weiAmount, r.currency);
        //amounts[0] represents how much ETH was actually sold        
        
        uint256 dust = r.weiAmount.sub(amounts[0]);
        
        uint256 totalLenderFee = computeLenderFee(r.cryptoAmount);
        uint256 totalBorrowerFee = computeBorrowerFee(r.weiAmount);

        if (totalBorrowerFee > dust) {
            totalBorrowerFee = dust;
        }
        
        if (r.currency == Currency.DAI) {
            daiFees = daiFees.add(totalLenderFee);
            depositedDAI[r.lender] += cryptoToTransfer.sub(totalLenderFee);
        } else {
            usdtFees = usdtFees.add(totalLenderFee);
            depositedUSDT[r.lender] += cryptoToTransfer.sub(totalLenderFee);
        }

        ethFees = ethFees.add(totalBorrowerFee);
        depositedWEI[r.borrower] += dust.sub(totalBorrowerFee);
        
        emit CollateralSoldBorrower(_requestId, r.borrower, r.weiAmount, amounts[0], cryptoToTransfer, dust.sub(totalBorrowerFee), totalBorrowerFee);
        emit CollateralSoldLender(_requestId, r.lender, r.weiAmount, amounts[0], cryptoToTransfer, cryptoToTransfer.sub(totalLenderFee), totalLenderFee);
    }
    
    function sellCollateralInUniswap(uint256 tokensToTransfer, uint256 weiAmount, Currency currency) internal returns (uint256[] memory)  {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        
        if (currency == Currency.DAI) {
            path[1] = address(daiToken);
        } else {
            path[1] = address(usdtToken);
        }
        
        return uniswapRouter.swapETHForExactTokens{value:weiAmount}(tokensToTransfer, path, address(this), block.timestamp);
    }

    function canBurnCollateralForDAI(uint256 requestId, uint256 daiVsWeiCurrentPrice) public view returns (bool) {
        Request memory r = requests[requestId];
        
        uint256 howMuchEthTheUserCanGet = r.cryptoAmount.mul(daiVsWeiCurrentPrice).div(1e18);
        uint256 eigthyPercentOfCollateral = r.weiAmount.mul(8).div(10);
        
        return howMuchEthTheUserCanGet > eigthyPercentOfCollateral;
    }    

    function canBurnCollateralForUSDT(uint256 requestId, uint256 usdtVsWeiCurrentPrice) public view returns (bool) {
        Request memory r = requests[requestId];
        
        uint256 howMuchEthTheUserCanGet = r.cryptoAmount.mul(usdtVsWeiCurrentPrice).div(1e6);
        uint256 eigthyPercentOfCollateral = r.weiAmount.mul(8).div(10);
        
        return howMuchEthTheUserCanGet > eigthyPercentOfCollateral;
    }    
    
    //Calculates the amount of WEI that is needed as a collateral for this amount of DAI and the chosen LTV
    function calculateWeiAmountForDAI(uint256 _daiAmount, uint256 _ltv, uint256 _daiVsWeiCurrentPrice) public pure returns (uint256) {
        //I calculate the collateral in DAI, then I change it to WEI and I remove the decimals from the token
        return _daiAmount.mul(100).div(_ltv).mul(_daiVsWeiCurrentPrice).div(1e18);
    }

    //Calculates the amount of WEI that is needed as a collateral for this amount of USDT and the chosen LTV
    function calculateWeiAmountForUSDT(uint256 _usdtAmount, uint256 _ltv, uint256 _usdtVsWeiCurrentPrice) public pure returns (uint256) {
        //I calculate the collateral in USDT, then I change it to WEI and I remove the decimals from the token
        return _usdtAmount.mul(100).div(_ltv).mul(_usdtVsWeiCurrentPrice).div(1e6);
    }

    function calculateCollateralForDAI(uint256 daiAmount, uint256 ltv) public view returns (uint256) {
        //Gets the current price in WEI for 1 DAI
        uint256 daiVsWeiCurrentPrice = uint256(priceConsumerDAI.getLatestPrice());
        //Gets the collateral needed in WEI
        return calculateWeiAmountForDAI(daiAmount, ltv, daiVsWeiCurrentPrice);
    }
    
    function calculateCollateralForUSDT(uint256 usdtAmount, uint256 ltv) public view returns (uint256) {
        //Gets the current price in WEI for 1 USDT
        uint256 usdtVsWeiCurrentPrice = uint256(priceConsumerUSDT.getLatestPrice());
        //Gets the collateral needed in WEI
        return calculateWeiAmountForUSDT(usdtAmount, ltv, usdtVsWeiCurrentPrice);
    }
    
    function getLatestDAIVsWeiPrice() public view returns (uint256) {
        return uint256(priceConsumerDAI.getLatestPrice());
    }

    function getLatestUSDTVsWeiPrice() public view returns (uint256) {
        return uint256(priceConsumerUSDT.getLatestPrice());
    }
    
    function getInterest(uint256 _ltv, uint256 _amount) public view returns (uint256) {
        require(interests[_ltv] > 0, "invalid LTV");
        return _amount.mul(interests[_ltv]).div(100);
    }
    
    function computeLenderFee(uint256 _value) public view returns (uint256) {
        return _value.mul(lenderFee).div(100); 
    }

    function computeBorrowerFee(uint256 _value) public view returns (uint256) {
        return _value.mul(borrowerFee).div(100); 
    }
    
    function getExpirationAfter(uint256 amountOfDays) public view returns (uint256) {
        return block.timestamp.add(amountOfDays.mul(1 days));
    }
    
    // Withdraw and Deposit functions
    
    function withdrawUSDT(uint256 _amount) public {
        require(depositedUSDT[msg.sender] >= _amount, "Not enough USDT deposited");
        require(ERC20(usdtToken).balanceOf(address(this)) >= _amount, "Not enough balance in contract");
        
        depositedUSDT[msg.sender] = depositedUSDT[msg.sender].sub(_amount);
        ERC20(usdtToken).safeTransfer(msg.sender, _amount);
        
        emit CoinWithdrawn(msg.sender, _amount, Currency.USDT);
    }

    function withdrawDAI(uint256 _amount) public {
        require(depositedDAI[msg.sender] >= _amount, "Not enough DAI deposited");
        require(daiToken.balanceOf(address(this)) >= _amount, "Not enough balance in contract");
        
        depositedDAI[msg.sender] = depositedDAI[msg.sender].sub(_amount);
        require(daiToken.transfer(msg.sender, _amount));
        
        emit CoinWithdrawn(msg.sender, _amount, Currency.DAI);
    }
    
    function withdrawETH(uint256 _amount) public {
        require(depositedWEI[msg.sender] >= _amount, "Not enough ETH deposited");
        require(address(this).balance >= _amount, "Not enough balance in contract");
        
        depositedWEI[msg.sender] = depositedWEI[msg.sender].sub(_amount);
        msg.sender.transfer(_amount);
        
        emit CoinWithdrawn(msg.sender, _amount, Currency.ETH);
    }
    
        function _updateNexenTokenAddress(IERC20 _nexenToken) public onlyOwner {
        nexenToken = _nexenToken;
    }

    function depositETH() public payable {
        require(msg.value > 10000000000000000, 'Minimum is 0.01 ETH');
        depositedWEI[msg.sender] += msg.value;

        emit CoinDeposited(msg.sender, msg.value, Currency.ETH);
    }

    function depositDAI(uint256 _amount) public {
        require(IERC20(daiToken).transferFrom(msg.sender, address(this), _amount), "Couldn't take the DAI from the sender");
        depositedDAI[msg.sender] += _amount;

        emit CoinDeposited(msg.sender, _amount, Currency.DAI);
    }
    
    
    function depositUSDT(uint256 _amount) public {
        ERC20(usdtToken).safeTransferFrom(msg.sender, address(this), _amount);
        depositedUSDT[msg.sender] += _amount;
        
        emit CoinDeposited(msg.sender, _amount, Currency.USDT);
    }
    
    //Admin functions
        
    function _expireRequest(uint256 _requestId) public onlyOwner {
        Request storage r = requests[_requestId];

        require(r.state == RequestState.Matched, "State needs to be Matched");
        
        if (r.currency == Currency.DAI) {
            uint256 daiVsWeiCurrentPrice = uint256(priceConsumerDAI.getLatestPrice());
            require(canBurnCollateralForDAI(_requestId, daiVsWeiCurrentPrice), "We cannot burn the collateral");
        } else {
            uint256 usdtVsWeiCurrentPrice = uint256(priceConsumerUSDT.getLatestPrice());
            require(canBurnCollateralForUSDT(_requestId, usdtVsWeiCurrentPrice), "We cannot burn the collateral");
        }
        
        r.state = RequestState.Disabled;

        burnCollateral(_requestId, r);
    }
    
    function _setInterest(uint256 _ltv, uint256 _interest) public onlyOwner {
        interests[_ltv] = _interest;
    }
    
    function _withdrawFees(Currency currency) public onlyOwner {
        if (currency == Currency.ETH) {
            uint256 amount = ethFees;
            ethFees = 0;
            msg.sender.transfer(amount);
        } else if (currency == Currency.USDT) {
            uint256 amount = usdtFees;
            usdtFees = 0;
            ERC20(usdtToken).safeTransfer(msg.sender, amount);
        } else { 
            uint256 amount = daiFees;
            daiFees = 0;
            require(daiToken.transfer(msg.sender, amount), "Transfer failed");
        }
    }
    
    function _setGenesisPhase(IERC20 _nexenToken, bool _genesisPhase, uint256 _amountToReward) public onlyOwner {
        nexenToken = _nexenToken;
        genesisPhase = _genesisPhase;
        amountToReward = _amountToReward;
    }
    
    function _setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }
    
    function _recoverNexenTokens(uint256 _amount) public onlyOwner {
        require(nexenToken.transfer(msg.sender, _amount), 'Could not transfer tokens');
    }
    
    function requestInfo(uint256 requestId) public view  returns (uint256 _tradeId, RequestState _state, address _borrower, address _lender, uint256 _cryptoAmount, uint256 _durationInDays, uint256 _expireIfNotMatchedOn, uint256 _ltv, uint256 _weiAmount, uint256 _tokenVsWeiCurrentPrice, uint256 _lendingFinishesOn, Currency currency) {
        Request storage r = requests[requestId];
        uint256 tokenVsWeiCurrentPrice = r.daiVsWeiCurrentPrice;
        if (r.currency == Currency.USDT) {
            tokenVsWeiCurrentPrice = r.usdtVsWeiCurrentPrice;
        }
        return (requestId, r.state, r.borrower, r.lender, r.cryptoAmount, r.durationInDays, r.expireIfNotMatchedOn, r.ltv, r.weiAmount, tokenVsWeiCurrentPrice, r.lendingFinishesOn, r.currency);
    }
}
