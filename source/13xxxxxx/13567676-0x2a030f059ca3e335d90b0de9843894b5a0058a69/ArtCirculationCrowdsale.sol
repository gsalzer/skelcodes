/** 
 *  SourceUnit: c:\Users\Jad\Documents\code\NFTC\nftc-monorepo\blockend\contracts\tokens\ArtCirculationCrowdsale.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
        assembly {
            size := extcodesize(account)
        }
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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




/** 
 *  SourceUnit: c:\Users\Jad\Documents\code\NFTC\nftc-monorepo\blockend\contracts\tokens\ArtCirculationCrowdsale.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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




/** 
 *  SourceUnit: c:\Users\Jad\Documents\code\NFTC\nftc-monorepo\blockend\contracts\tokens\ArtCirculationCrowdsale.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}




/** 
 *  SourceUnit: c:\Users\Jad\Documents\code\NFTC\nftc-monorepo\blockend\contracts\tokens\ArtCirculationCrowdsale.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}




/** 
 *  SourceUnit: c:\Users\Jad\Documents\code\NFTC\nftc-monorepo\blockend\contracts\tokens\ArtCirculationCrowdsale.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}




/** 
 *  SourceUnit: c:\Users\Jad\Documents\code\NFTC\nftc-monorepo\blockend\contracts\tokens\ArtCirculationCrowdsale.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "../IERC20.sol";
////import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}




/** 
 *  SourceUnit: c:\Users\Jad\Documents\code\NFTC\nftc-monorepo\blockend\contracts\tokens\ArtCirculationCrowdsale.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

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
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


/** 
 *  SourceUnit: c:\Users\Jad\Documents\code\NFTC\nftc-monorepo\blockend\contracts\tokens\ArtCirculationCrowdsale.sol
*/

/////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity >=0.4.22 <0.9.0;

/// @notice access control base class
////import "../../node_modules/@openzeppelin/contracts/access/Ownable.sol";

/// @notice ERC20 interface class
////import "../../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice ERC20 interface class
////import "../../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice SafeMath library for uint calculations with overflow protections
////import "../../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @notice Security: ReentrancyGuard class
////import "../../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title Crowdsale
 * @notice ERC20-ready ICO smart contract for ACT & ACG token
 * @author Jad A. Jabbour @ NFT Contemporary
**/
contract ArtCirculationCrowdsale is
            Ownable,
            ReentrancyGuard
{
    /// @notice using safe math for uints
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    /// @notice Enum representing crowdsale phases
    enum Phase {
        Seed,
        Public1, 
        Public2, 
        Public3, 
        Public4,
        Paused,
        Stopped
    }

    /// @notice on sale ACT token 
    IERC20 private _acToken;

    /// @notice on sale Governance token 
    IERC20 private _gToken;

    /// @notice Address where funds are collected
    address payable private _wallet;

    /// @notice The rate per 1 wei of funds received for ACT per phase
    mapping(Phase => uint256) private _actRate;

    /// @notice The rate per 1 wei of funds received for Governance per phase
    mapping(Phase => uint256) private _gRate;

    /// @notice Amount of wei raised per Phase
    mapping(Phase => uint256) private _weiRaised;

    /// @notice Total amount of wei raised
    uint256 private _totWeiRaised;

    /// @notice the address whitelist for restricted tokens mapped by phase by token
    mapping(Phase => mapping(address => mapping(address => bool))) private _whitelist;

    /// @notice the address whitelist for restricted tokens mapped by phase by token
    mapping(Phase => mapping(address => bool)) private _shouldWhitelistCheck;

    /// @notice crowdsale timeframe
    mapping(Phase => uint32) private _openingTime;
    mapping(Phase => uint32) private _closingTime;

    /// @notice public record of ether transfered to this contract per address per phase
    mapping(Phase => mapping(address => mapping(address => uint))) public record;

    /// @notice the current phase of the crowdsale
    Phase private _phase;

    /// @notice whitelist modifier
    modifier requireWhitelist(address token){
        require(token != address(0), 'ACC:Internal error::token address missing');
        if(_shouldWhitelistCheck[_phase][token]){
            require(_whitelist[_phase][token][_msgSender()], 'ACC::Whitelisted buyers only');
        }
        _;
    }

    /// @notice open/close time restriction modifier with phase checker
    modifier openCloseRestrict(){
        require(_phase != Phase.Paused && _phase != Phase.Stopped, 'ACC::Crowdsale is paused or stopped');
        require(block.timestamp >= _openingTime[_phase], 'ACC::Crowdsale has not begun yet'); /* solium-disable-line */
        require(block.timestamp < _closingTime[_phase], 'ACC::Crowdsale has already ended'); /* solium-disable-line */
        _;
    }

    /**
     * @notice Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     * @param token address of the token contract
     * @param phase the crowdsale phase this purcahse was registered at
    **/
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint value, uint amount, address token, Phase phase);

    /**
     * @notice Event published when a phase is triggered
     * @param phase the crowdsale phase this purcahse was registered at
    **/
    event PhaseTriggered(Phase phase, uint act_rate, uint g_rate);

    /**
     * @notice constructor
     * @param acToken the crowdsaled ACT token
     * @param gToken the crowdsaled ACG token
     * @param actRate the rate at which the ACT token is being sold per wei @ Seed phase
     * @param gRate the rate at which the ACG token is being sold per wei @ Seed phase
     * @param wallet the wallet that will recieve te funds paid by accounts
     * @param act_whitelist whitelisted addresses for ACT token purchase elligibility @ Seed phase
     * @param g_whitelist whitelisted addresses for governance token purchase elligibility @ Seed phase
     * @param openingAt the opening timestamp for the crowdsale @ Seed phase
     * @param closingAt the closing timestamp for the crowdsale @ Seed phase
    **/
    constructor (
        IERC20 acToken,
        IERC20 gToken,
        uint actRate,
        uint gRate,
        address payable wallet,
        address[] memory act_whitelist,
        address[] memory g_whitelist,
        uint32 openingAt, 
        uint32 closingAt 
    ) Ownable() ReentrancyGuard() {
        __ArtCirculationCrowdsale_init(acToken, gToken, actRate, gRate, wallet, act_whitelist, g_whitelist, openingAt, closingAt);
    }

    /**
     * @notice The rate is the conversion between wei and the smallest and indivisible
     * token unit. So, if you are using a rate of 1 with a ERC20Detailed token
     * with 3 decimals called TOK, 1 wei will give you 1 unit, or 0.001 TOK.
     * @param acToken the crowdsaled ACT token
     * @param gToken the crowdsaled ACG token
     * @param actRate the rate at which the ACT token is being sold per wei @ Seed phase
     * @param gRate the rate at which the ACG token is being sold per wei @ Seed phase
     * @param wallet the wallet that will recieve te funds paid by accounts
     * @param act_whitelist whitelisted addresses for ACT token purchase elligibility @ Seed phase
     * @param g_whitelist whitelisted addresses for governance token purchase elligibility @ Seed phase
     * @param openingAt the opening timestamp for the crowdsale @ Seed phase
     * @param closingAt the closing timestamp for the crowdsale @ Seed phase
    **/
    function __ArtCirculationCrowdsale_init(
        IERC20 acToken,
        IERC20 gToken,
        uint actRate,
        uint gRate,
        address payable wallet,
        address[] memory act_whitelist,
        address[] memory g_whitelist,
        uint32 openingAt, 
        uint32 closingAt 
    ) internal {
        require(actRate > 0, "ACC: rate is 0");
        require(gRate > 0, "ACC: rate is 0");
        require(wallet != address(0), "ACC: wallet is the zero address");
        require(address(acToken) != address(0), "ACC: token is the zero address");
        require(address(gToken) != address(0), "ACC: token is the zero address");
        require(openingAt > block.timestamp, "ACC: invalid seed start time");
        require(closingAt > openingAt, "ACC: invalid seed end time");

        _phase = Phase.Seed;
        _actRate[_phase] = actRate;
        _gRate[_phase] = gRate;
        _wallet = wallet;
        _acToken = acToken;
        _gToken = gToken;
        _openingTime[_phase] = openingAt;
        _closingTime[_phase] = closingAt;

        /// @notice lock Seed phase to whitelist
        _shouldWhitelistCheck[_phase][address(acToken)] = true;
        _shouldWhitelistCheck[_phase][address(gToken)] = true;

        /// @notice populate whitelist for ACT
        for(uint i=0;i<act_whitelist.length;i++){
            _whitelist[_phase][address(_acToken)][act_whitelist[i]] = true;
        }

        /// @notice populate whitelist for ACG
        for(uint i=0;i<g_whitelist.length;i++){
            _whitelist[_phase][address(_gToken)][g_whitelist[i]] = true;
        }
    }

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     * @notice that other contracts will transfer funds with a base gas stipend
     * of 2300, which is not enough to call buyTokens. Consider calling
     * buyTokens directly when purchasing tokens from a contract.
    **/
    receive() external payable {
        revert('ACC: Use buyTokens or buyGTokens');
    }

    /// @notice gets the current phase of the crowdsale and the open/close time 
    function getPhase() public view returns (Phase, uint32, uint32) {
        return (_phase, _openingTime[_phase], _closingTime[_phase]);
    }

    /**
     * @notice Updates the phase rates and the open/close times and whitelists
     * @param phase the phase ID to set next
     * @param actRate the rate at which the ACT token is being sold per wei @ next phase
     * @param gRate the rate at which the ACG token is being sold per wei @ next phase
     * @param act_whitelist whitelisted addresses for ACT token purchase elligibility @ next phase
     * @param g_whitelist whitelisted addresses for governance token purchase elligibility @ next phase
     * @param openingAt the opening timestamp for the crowdsale @ next phase
     * @param closingAt the closing timestamp for the crowdsale @ next phase
    **/
    function setPhase(
        Phase phase, 
        uint actRate,
        uint gRate,
        address[] memory act_whitelist,
        address[] memory g_whitelist,
        uint32 openingAt,
        uint32 closingAt
    ) public onlyOwner{
        if(phase != Phase.Paused && phase != Phase.Stopped){
            require(actRate > 0, "ACC: rate is 0");
            require(gRate > 0, "ACC: rate is 0");
        }

        require(openingAt > block.timestamp, "ACC: invalid phase start time");
        require(closingAt > openingAt, "ACC: invalid phase end time");
        
        /// @notice set phase
        _phase = phase;

        /// @notice set phase rates
        _actRate[_phase] = actRate;
        _gRate[_phase] = gRate;

        /// @notice phase timeframe
        _openingTime[_phase] = openingAt; 
        _closingTime[_phase] = closingAt;

        /// @notice lock Seed phase to whitelist
        _shouldWhitelistCheck[_phase][address(_acToken)] = act_whitelist.length > 0;
        _shouldWhitelistCheck[_phase][address(_gToken)] = g_whitelist.length > 0;

        /// @notice populate whitelist for ACT
        for(uint i=0;i<act_whitelist.length;i++){
            _whitelist[_phase][address(_acToken)][act_whitelist[i]] = true;
        }

        /// @notice populate whitelist for ACG
        for(uint i=0;i<g_whitelist.length;i++){
            _whitelist[_phase][address(_gToken)][g_whitelist[i]] = true;
        }

        emit PhaseTriggered(_phase, actRate, gRate); 
    }

    /**
     * @return the tokens being sold.
    **/
    function tokensOnSale() public view returns (IERC20, IERC20) {
        return (_acToken, _gToken);
    }

    /**
     * @return the address where funds are collected.
    **/
    function collectorWallet() public view returns (address payable) {
        return _wallet;
    }

    /**
     * @return the number of tokens units a buyer gets per wei.
    **/
    function rates() public view returns (uint, uint) {
        return (_actRate[_phase], _gRate[_phase]);
    }

    /**
     * @return the amount of wei raised in current phase
    **/
    function phaseWeiRaised() public view returns (uint) {
        return _weiRaised[_phase];
    }    
    
    /**
     * @return the amount of wei raised current phase
    **/
    function totalWeiRaised() public view returns (uint) {
        return _totWeiRaised;
    }

    /// @return whether an address is whitelisted or not
    function isWhitelisted(address toCheck, address token) public view returns (bool){
        require(toCheck != address(0), 'ACC::Address cannot be 0');
        require(token != address(0), 'ACC::Address cannot be 0');
        return _shouldWhitelistCheck[_phase][token] ? _whitelist[_phase][token][toCheck] : true;
    }

    /**
     * @notice changes the collector wallet address
    **/
    function changeCollectorWallet(address payable _payable) public onlyOwner {
        require(_payable != address(0), 'ACC:: Address cannot be 0');
        _wallet = _payable;
    }

    /// @notice adds an address to the whitelist for current phase for specific token
    function addWhitelist(address toAdd, address token) public onlyOwner returns (bool){
        require(toAdd != address(0), 'ACC::Address cannot be 0');
        _whitelist[_phase][token][toAdd] = true;
        return _whitelist[_phase][token][toAdd];
    } 

    /// @notice removes an address to the whitelist for current phase for specific token
    function removeWhitelist(address toRemove, address token) public onlyOwner returns (bool){
        require(toRemove != address(0), 'ACC::Address cannot be 0');
        _whitelist[_phase][token][toRemove] = false;
        return !_whitelist[_phase][token][toRemove];
    } 

    /**
     * @notice buyToken can be called directly as opposed to the payable fallback
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
    **/
    function buyTokens() public nonReentrant openCloseRestrict requireWhitelist(address(_acToken)) payable {
        uint weiAmount = msg.value;
        address beneficiary = _msgSender();
        _preValidatePurchase(beneficiary, weiAmount);

        uint tokens = _getTokenAmount(weiAmount);
        _totWeiRaised = _totWeiRaised.add(weiAmount);
        _weiRaised[_phase] = _weiRaised[_phase].add(weiAmount);
        _processPurchase(beneficiary, tokens, _acToken);

        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens, address(_acToken), _phase);

        _updatePurchasingState(beneficiary, weiAmount, address(_acToken));
        _postValidatePurchase();
    }

    /**
     * @notice buyGToken can be called directly as opposed to the payable fallback
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
    **/
    function buyGTokens() public nonReentrant openCloseRestrict requireWhitelist(address(_gToken)) payable {
        uint weiAmount = msg.value;
        address beneficiary = _msgSender();
        _preValidatePurchase(beneficiary, weiAmount);

        uint tokens = _getGTokenAmount(weiAmount);
        _totWeiRaised = _totWeiRaised.add(weiAmount);
        _weiRaised[_phase] = _weiRaised[_phase].add(weiAmount);
        _processPurchase(beneficiary, tokens, _gToken);

        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens, address(_gToken), _phase);

        _updatePurchasingState(beneficiary, weiAmount, address(_gToken));
        _postValidatePurchase();
    }

    /**
     * @notice Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
    **/
    function _preValidatePurchase(address beneficiary, uint weiAmount) internal view {
        require(beneficiary != address(0), "ACC: beneficiary is the zero address");
        require(weiAmount != 0, "ACC: weiAmount is 0");
        this;
    }

    /**
     * @notice Validation of an executed purchase. and fund forwarding
    **/
    function _postValidatePurchase() internal { /* solium-disable-line */
        /// @notice forward fund to receiver wallet
        _forwardFunds();
    }

    /**
     * @notice Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
    **/
    function _deliverTokens(address beneficiary, uint tokenAmount, IERC20 toToken) internal {
        toToken.safeTransfer(beneficiary, tokenAmount);
    }

    /**
     * @notice Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
    **/
    function _processPurchase(address beneficiary, uint tokenAmount, IERC20 toToken) internal {
        _deliverTokens(beneficiary, tokenAmount, toToken);
    }

    /**
     * @notice Override for extensions that require an internal state to check for validity
     * @param beneficiary Address receiving the tokens
     * @param weiAmount Value in wei involved in the purchase
     * @param toToken the token purchased by the account
    **/
    function _updatePurchasingState(address beneficiary, uint weiAmount, address toToken) internal { /* solium-disable-line */
        /// @notice adds the amount of wei to the account record for the current phase
        record[_phase][toToken][beneficiary] = record[_phase][toToken][beneficiary].add(weiAmount);
    }

    /**
     * @notice Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
    **/
    function _getTokenAmount(uint weiAmount) internal view returns (uint) {
        return weiAmount.mul(_actRate[_phase]);
    }

    /**
     * @notice Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of G tokens that can be purchased with the specified _weiAmount
    **/
    function _getGTokenAmount(uint weiAmount) internal view returns (uint) {
        return weiAmount.mul(_gRate[_phase]);
    }

    /**
     * @notice Determines how ETH is stored/forwarded on purchases.
    **/
    function _forwardFunds() internal {
        /// @notice forward fund to receiver wallet using CALL to avoid 2300 stipend limit
        (bool success,) = _wallet.call{value: msg.value}('');
        require(success, 'ACC:: Failed to forward funds');
    }
}
