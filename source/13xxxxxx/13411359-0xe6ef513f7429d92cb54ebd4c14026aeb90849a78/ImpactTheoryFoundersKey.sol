// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol



pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol



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

// File: @openzeppelin/contracts/utils/Strings.sol



pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/security/Pausable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity ^0.8.0;

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
     * IMPORTANT: because control is transferred to `recipient`, care must be
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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol



pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol



pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol



pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol



pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol



pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol



pragma solidity ^0.8.0;



/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol



pragma solidity ^0.8.0;



/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol



pragma solidity ^0.8.0;



/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// File: ImpactTheoryFoundersKey.sol


pragma solidity ^0.8.0;








/**
 *
 * Impact Theory Founders Key
 *
 */
contract ImpactTheoryFoundersKey is
    Ownable,
    ERC721Burnable,
    ERC721Enumerable,
    ERC721Pausable
{
    using SafeMath for uint256;
    using Strings for uint256;
    using ECDSA for bytes32;

    // Public tier info
    struct Tier {
        uint256 id;
        string name;
    }

    // Private tier info
    struct TierInfo {
        Tier tier;
        uint256 startingOffset;
        uint256 totalSupply;
        uint256 startingPrice;
        uint256 endingPrice;
        uint256 maxPerClosedPresale;
        uint256 maxTotalMint;
        bool saleEnded;
    }

    // Base token uri
    string private baseTokenURI; // baseTokenURI can point to IPFS folder like https://ipfs.io/ipfs/{cid}/ while
    string private baseTokenURIForMetadata; // baseTokenURIForMetadata should point to the raw IPFS endpoint because it will not use IPFS folders. For example: https://ipfs.io/ipfs/

    // For uint to bytes32 conversion
    bytes16 private constant HEX_ALPHABET = "0123456789abcdef";
    string private constant IPFS_PREFIX = "f01551220"; // IPFS byte (f) + CID v1 (0x01) + raw codec (0x55) + SHA256 (0x12) + 256 bits long (0x20)

    // Payment address
    address private paymentAddress = 0x681EA99a65E6f392f0F5276Af396AE8CaD140E6D;

    // Royalties address
    address private royaltyAddress = 0x681EA99a65E6f392f0F5276Af396AE8CaD140E6D;

    // Signer address
    address private signerAddress = 0x4A2034e724034F31b46117d918E789c42EBE0CF2;

    // Royalties basis points (percentage using 2 decimals - 10000 = 100, 0 = 0)
    uint256 private royaltyBasisPoints = 1000; // 10%

    // Token info
    string public constant TOKEN_NAME = "Impact Theory Founder's Key";
    string public constant TOKEN_SYMBOL = "ITFK";

    // Sale durations
    uint256 public constant CLOSED_PRESALE_DURATION = 1 days;
    uint256 public constant PRESALE_DURATION = 1 days;
    uint256 public constant AUCTION_DURATION = 1 days;
    uint256 public constant AUCTION_PRICE_CHANGE = 1 hours;
    uint256 public constant DURATION_BETWEEN_TIERS = 1 days;

    // Public sale params
    uint256 public publicSaleStartTime;
    bool public publicSaleActive;

    //-- Tiers --//
    // Tier 1 - public info
    Tier public tier1 = Tier({id: 1, name: "Legendary"});

    // Tier 1 - private info
    TierInfo private tier1Info =
        TierInfo({
            tier: tier1,
            startingOffset: 1,
            totalSupply: 2700,
            startingPrice: 3 ether,
            endingPrice: 1.5 ether,
            maxPerClosedPresale: 1,
            maxTotalMint: 4,
            saleEnded: false
        });

    // Tier 2 - public info
    Tier public tier2 = Tier({id: 2, name: "Heroic"});

    // Tier 2 - private info
    TierInfo private tier2Info =
        TierInfo({
            tier: tier2,
            startingOffset: 2701,
            totalSupply: 7300,
            startingPrice: 1.5 ether,
            endingPrice: .75 ether,
            maxPerClosedPresale: 2,
            maxTotalMint: 5,
            saleEnded: false
        });

    // Tier 3 - public info
    Tier public tier3 = Tier({id: 3, name: "Relentless"});

    // Tier 3 - private info
    TierInfo private tier3Info =
        TierInfo({
            tier: tier3,
            startingOffset: 10001,
            totalSupply: 10000,
            startingPrice: .1 ether,
            endingPrice: .05 ether,
            maxPerClosedPresale: 1,
            maxTotalMint: 5,
            saleEnded: false
        });

    Tier[] public allTiersArray;
    TierInfo[] private allTiersInfoArray;

    uint256[] public allTierIds;

    mapping(uint256 => Tier) public allTiers;
    mapping(uint256 => TierInfo) private allTiersInfo;

    mapping(uint256 => Tier) public tokenTier;

    mapping(uint256 => uint256) public tokenMintedAt;
    mapping(uint256 => uint256) public tokenLastTransferredAt;

    mapping(uint256 => uint256) public tierCounts;

    mapping(uint256 => bytes32[]) public tokenMetadata;

    // Presale whitelist per tier
    mapping(address => uint256[]) private presaleWhitelist;

    // Used nonces for mint signatures
    mapping(string => bool) private usedNonces;

    //-- Events --//

    event PublicSaleStart(uint256 indexed _saleStartTime);
    event PublicSalePaused(uint256 indexed _timeElapsed);
    event PublicSaleActive(bool indexed _publicSaleActive);
    event RoyaltyBasisPoints(uint256 indexed _royaltyBasisPoints);

    //-- Modifiers --//

    // Public sale active modifier
    modifier whenPublicSaleActive() {
        require(publicSaleActive, "Public sale is not active");
        _;
    }

    // Public sale not active modifier
    modifier whenPublicSaleNotActive() {
        require(
            !publicSaleActive && publicSaleStartTime == 0,
            "Public sale is already active"
        );
        _;
    }

    // Owner or public sale active modifier
    modifier whenOwnerOrPublicSaleActive() {
        require(
            owner() == _msgSender() || publicSaleActive,
            "Public sale is not active"
        );
        _;
    }

    // -- Constructor --//
    constructor(string memory _baseTokenURI) ERC721(TOKEN_NAME, TOKEN_SYMBOL) {
        baseTokenURI = _baseTokenURI;

        // Setup intial tiers and tiers info
        Tier[3] memory allTiersArrayMem = [tier1, tier2, tier3];
        TierInfo[3] memory allTiersInfoArrayMem = [
            tier1Info,
            tier2Info,
            tier3Info
        ];

        for (uint256 i = 0; i < allTiersArrayMem.length; i++) {
            uint256 tierId = allTiersArrayMem[i].id;

            // Tier arrays
            allTiersArray.push(allTiersArrayMem[i]);
            allTiersInfoArray.push(allTiersInfoArrayMem[i]);

            allTierIds.push(tierId);

            // Tier mappings
            allTiers[tierId] = allTiersArray[i];
            allTiersInfo[tierId] = allTiersInfoArray[i];
        }
    }

    // -- External Functions -- //

    // Start public sale
    function startPublicSale() external onlyOwner whenPublicSaleNotActive {
        publicSaleStartTime = block.timestamp;
        publicSaleActive = true;
        emit PublicSaleStart(publicSaleStartTime);
    }

    // Set this value to the block.timestamp you'd like to reset to
    // Created as a way to fast foward in time for tier timing unit tests
    // Can also be used if needing to pause and restart public sale from original start time (returned in startPublicSale() above)
    function setPublicSaleStartTime(uint256 _publicSaleStartTime)
        external
        onlyOwner
    {
        publicSaleStartTime = _publicSaleStartTime;
        emit PublicSaleStart(publicSaleStartTime);
    }

    // Toggle public sale
    function togglePublicSaleActive() external onlyOwner {
        publicSaleActive = !publicSaleActive;
        emit PublicSaleActive(publicSaleActive);
    }

    // Pause public sale
    function pausePublicSale() external onlyOwner whenPublicSaleActive {
        publicSaleActive = false;
        emit PublicSalePaused(getElapsedSaleTime());
    }

    // End tier sale
    function setTierSaleEnded(uint256 _tierId, bool _saleEnded)
        external
        onlyOwner
        whenPublicSaleActive
    {
        allTiersInfo[_tierId].saleEnded = _saleEnded;
    }

    // Get all tiers
    function getAllTiers() external view returns (Tier[] memory) {
        return allTiersArray;
    }

    // Get all tiers info
    function getAllTiersInfo()
        external
        view
        onlyOwner
        returns (TierInfo[] memory)
    {
        return allTiersInfoArray;
    }

    // Support royalty info - See {EIP-2981}: https://eips.ethereum.org/EIPS/eip-2981
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (
            royaltyAddress,
            (_salePrice.mul(royaltyBasisPoints)).div(10000)
        );
    }

    // Adds multiple address to presale whitelist for specific tier
    function addToPresaleWhitelist(uint256 _tierId, address[] memory _addresses)
        external
        onlyOwner
    {
        Tier memory tier = allTiers[_tierId];

        require(tier.id == _tierId, "Invalid tier");

        for (uint256 i = 0; i < _addresses.length; i++) {
            address _address = _addresses[i];

            uint256[] storage tierIds = presaleWhitelist[_address];

            bool exists = false;
            for (uint256 j = 0; j < tierIds.length; j++) {
                if (tierIds[j] == tier.id) {
                    exists = true;
                }
            }

            if (!exists) {
                tierIds.push(tier.id);
            }

            presaleWhitelist[_address] = tierIds;
        }
    }

    // Removes single address from whitelist for specific tier
    function removeFromPresaleWhitelist(uint256 _tierId, address _address)
        external
        onlyOwner
    {
        Tier memory tier = allTiers[_tierId];

        require(tier.id == _tierId, "Invalid tier");

        uint256[] storage tierIds = presaleWhitelist[_address];

        // Loop over each tier id
        for (uint256 i = 0; i < tierIds.length; i++) {
            if (tierIds[i] == tier.id) {
                // If tier id is found, replace with last tier id
                tierIds[i] = tierIds[tierIds.length - 1];
            }
        }

        // Remove last tier id, since it replaced the matched tier id
        tierIds.pop();

        presaleWhitelist[_address] = tierIds;
    }

    // Get all tiers address is whitelisted for
    function getPresaleWhitelist(address _address)
        external
        view
        onlyOwner
        returns (uint256[] memory)
    {
        return presaleWhitelist[_address];
    }

    //-- Public Functions --//

    // Get elapsed sale time
    function getElapsedSaleTime() public view returns (uint256) {
        return
            publicSaleStartTime > 0
                ? block.timestamp.sub(publicSaleStartTime)
                : 0;
    }

    // Get remaining closed presale time
    function getRemainingClosedPresaleTime(uint256 _tierId)
        public
        view
        whenPublicSaleActive
        returns (uint256)
    {
        Tier memory tier = allTiers[_tierId];

        require(tier.id == _tierId, "Invalid tier");

        // Get elapsed sale time
        uint256 elapsed = getElapsedSaleTime();

        // Time logic based on tier and constants
        uint256 closedPresaleStart = (tier.id - 1).mul(DURATION_BETWEEN_TIERS);
        uint256 closedPresaleEnd = closedPresaleStart.add(
            CLOSED_PRESALE_DURATION
        );

        // Tier not active
        require(elapsed >= closedPresaleStart, "Tier not active");

        // Tier finished presale
        if (elapsed >= closedPresaleEnd) {
            return 0;
        }

        // Elasped time since presale start
        uint256 elapsedSinceStart = elapsed.sub(closedPresaleStart);

        // Total duration minus elapsed time since presale start
        return CLOSED_PRESALE_DURATION.sub(elapsedSinceStart);
    }

    // Get remaining presale time
    function getRemainingPresaleTime(uint256 _tierId)
        public
        view
        whenPublicSaleActive
        returns (uint256)
    {
        Tier memory tier = allTiers[_tierId];

        require(tier.id == _tierId, "Invalid tier");

        // Get elapsed sale time
        uint256 elapsed = getElapsedSaleTime();

        // Time logic based on tier and constants
        uint256 closedPresaleStart = (tier.id - 1).mul(DURATION_BETWEEN_TIERS);
        uint256 closedPresaleEnd = closedPresaleStart.add(
            CLOSED_PRESALE_DURATION
        );
        uint256 presaleStart = closedPresaleEnd;
        uint256 presaleEnd = presaleStart.add(PRESALE_DURATION);

        // Tier not active
        require(elapsed >= presaleStart, "Tier not active");

        // Tier finished presale
        if (elapsed >= presaleEnd) {
            return 0;
        }

        // Elasped time since presale start
        uint256 elapsedSinceStart = elapsed.sub(presaleStart);

        // Total duration minus elapsed time since presale start
        return PRESALE_DURATION.sub(elapsedSinceStart);
    }

    // Get remaining auction time
    function getRemainingAuctionTime(uint256 _tierId)
        public
        view
        whenPublicSaleActive
        returns (uint256)
    {
        Tier memory tier = allTiers[_tierId];

        require(tier.id == _tierId, "Invalid tier");

        uint256 elapsed = getElapsedSaleTime();

        // Time logic based on tier and constants
        uint256 closedPresaleStart = (tier.id - 1).mul(DURATION_BETWEEN_TIERS);
        uint256 closedPresaleEnd = closedPresaleStart.add(
            CLOSED_PRESALE_DURATION
        );
        uint256 presaleStart = closedPresaleEnd;
        uint256 presaleEnd = presaleStart.add(PRESALE_DURATION);
        uint256 auctionStart = presaleEnd;
        uint256 auctionEnd = auctionStart.add(AUCTION_DURATION);

        // Tier not active
        require(elapsed >= auctionStart, "Tier not active");

        // Tier finished auction
        if (elapsed >= auctionEnd) {
            return 0;
        }

        // Elasped time since auction start
        uint256 elapsedSinceStart = elapsed.sub(auctionStart);

        // Total duration minus elapsed time since auction start
        return AUCTION_DURATION.sub(elapsedSinceStart);
    }

    // Mint token - requires tier and amount
    function mint(
        uint256 _tierId,
        uint256 _amount,
        bytes32 _hash,
        bytes memory _signature,
        string memory _nonce
    ) public payable whenOwnerOrPublicSaleActive {
        require(
            matchAddressSigner(_hash, _signature),
            "Direct mint disallowed"
        );
        require(!usedNonces[_nonce], "Hash already used");
        require(
            hashTransaction(_msgSender(), _amount, _nonce) == _hash,
            "Hash failed"
        );

        Tier memory tier = allTiers[_tierId];
        TierInfo memory tierInfo = allTiersInfo[_tierId];

        require(tier.id == _tierId, "Invalid tier");

        // Must mint at least one
        require(_amount > 0, "Must mint at least one");

        // Check there enough mints left for tier
        require(
            getMintsLeft(tier.id).sub(_amount) >= 0,
            "Minting would exceed max supply"
        );

        // Get current address total balance
        uint256 currentTotalAmount = super.balanceOf(_msgSender());

        // Loop over all tokens for address and get current tier count
        uint256 currentTierAmount = 0;
        for (uint256 i = 0; i < currentTotalAmount; i++) {
            uint256 tokenId = super.tokenOfOwnerByIndex(_msgSender(), i);
            Tier memory _tokenTier = tokenTier[tokenId];
            if (_tokenTier.id == tier.id) {
                currentTierAmount++;
            }
        }

        uint256 costToMint = 0;
        uint256 amount = _amount;

        // Is owner
        bool isOwner = owner() == _msgSender();

        // If not owner, check amounts are not more than max amounts
        if (!isOwner) {
            // Get elapsed sale time
            uint256 elapsed = getElapsedSaleTime();

            // Time logic based on tier and constants
            uint256 closedPresaleStart = (tier.id - 1).mul(
                DURATION_BETWEEN_TIERS
            );
            uint256 closedPresaleEnd = closedPresaleStart.add(
                CLOSED_PRESALE_DURATION
            );

            // If still in the closed whitelist, do not allow more than max per closed presale
            if (elapsed <= closedPresaleEnd) {
                require(
                    currentTierAmount.add(amount) <= tierInfo.maxPerClosedPresale,
                    "Requested amount exceeds maximum whitelist mint amount"
                );
            }

            // Do not allow more than max total mint
            require(
                currentTierAmount.add(amount) <= tierInfo.maxTotalMint,
                "Requested amount exceeds maximum total mint amount"
            );
        }

        // Get cost to mint
        costToMint = getMintPrice(tier.id).mul(amount);

        // Check cost to mint for tier, and if enough ETH is passed to mint
        require(costToMint <= msg.value, "ETH amount sent is not correct");

        for (uint256 i = 0; i < amount; i++) {
            // Token id is tier starting offset plus count of already minted
            uint256 tokenId = tierInfo.startingOffset.add(tierCounts[tier.id]);

            // Safe mint
            _safeMint(_msgSender(), tokenId);

            // Attribute token id with tier
            tokenTier[tokenId] = tier;

            // Store minted at timestamp by token id
            tokenMintedAt[tokenId] = block.timestamp;

            // Increment tier counter
            tierCounts[tier.id] = tierCounts[tier.id].add(1);
        }

        usedNonces[_nonce] = true;

        // Send mint cost to payment address
        Address.sendValue(payable(paymentAddress), costToMint);

        // Return unused value
        if (msg.value > costToMint) {
            Address.sendValue(payable(_msgSender()), msg.value.sub(costToMint));
        }
    }

    // Burn multiple
    function burnMultiple(uint256[] memory _tokenIds) public onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            // Token id
            uint256 tokenId = _tokenIds[i];

            _burn(tokenId);
        }
    }

    // Get mint price
    function getMintPrice(uint256 _tierId)
        public
        view
        whenOwnerOrPublicSaleActive
        returns (uint256)
    {
        Tier memory tier = allTiers[_tierId];
        TierInfo memory tierInfo = allTiersInfo[_tierId];

        require(tier.id == _tierId, "Invalid tier");

        // Is owner
        bool isOwner = owner() == _msgSender();

        // If owner, cost is 0
        if (isOwner) {
            return 0;
        }

        uint256 elapsed = getElapsedSaleTime();
        uint256 currentPrice = 0;

        // Setup starting and ending prices
        uint256 startingPrice = tierInfo.startingPrice;
        uint256 endingPrice = tierInfo.endingPrice;

        // Time logic based on tier and constants

        uint256 closedPresaleStart = (tier.id - 1).mul(DURATION_BETWEEN_TIERS);
        uint256 closedPresaleEnd = closedPresaleStart.add(
            CLOSED_PRESALE_DURATION
        );
        uint256 presaleStart = closedPresaleEnd;
        uint256 presaleEnd = presaleStart.add(PRESALE_DURATION);
        uint256 auctionStart = presaleEnd;
        uint256 auctionEnd = auctionStart.add(AUCTION_DURATION);

        // Tier not active
        require(elapsed >= closedPresaleStart, "Tier not active");

        // Closed presale - starting price
        if ((elapsed >= closedPresaleStart) && (elapsed < presaleStart)) {
            // Must be in presale whitelist to get price and mint
            uint256[] memory whitelistedTiers = presaleWhitelist[_msgSender()];
            bool isWhitelisted = false;
            for (uint256 i = 0; i < whitelistedTiers.length; i++) {
                if (whitelistedTiers[i] == tier.id) {
                    isWhitelisted = true;
                }
            }

            require(isWhitelisted, "Tier not active, not whitelisted");
            currentPrice = startingPrice;

            // Presale - starting price
        } else if ((elapsed >= presaleStart) && (elapsed < presaleEnd)) {
            currentPrice = startingPrice;

            // Dutch Auction - price descreses dynamically for duration
        } else if ((elapsed >= auctionStart) && (elapsed < auctionEnd)) {
            uint256 elapsedSinceAuctionStart = elapsed.sub(auctionStart); // Elapsed time since auction start
            uint256 totalPriceDiff = startingPrice.sub(endingPrice); // Total price diff between starting and ending price
            uint256 numPriceChanges = AUCTION_DURATION.div(
                AUCTION_PRICE_CHANGE
            ).sub(1); // Amount of price changes in the auction
            uint256 priceChangeAmount = totalPriceDiff.div(numPriceChanges); // Amount of price change per instance of price change
            uint256 elapsedRounded = elapsedSinceAuctionStart.div(
                AUCTION_PRICE_CHANGE
            ); // Elapsed time since auction start rounded to auction price change variable
            uint256 totalPriceChangeAmount = priceChangeAmount.mul(
                elapsedRounded
            ); // Total amount of price change based on time

            currentPrice = startingPrice.sub(totalPriceChangeAmount); // Starting price minus total price change

            // Post auction - ending price
        } else if (elapsed >= auctionEnd) {
            // Check if tier ended
            require(!tierInfo.saleEnded, "Tier not active");

            currentPrice = endingPrice;
        }

        // Double check current price is not lower than ending price
        return currentPrice < endingPrice ? endingPrice : currentPrice;
    }

    // Get mints left for tier
    function getMintsLeft(uint256 _tierId)
        public
        view
        whenOwnerOrPublicSaleActive
        returns (uint256)
    {
        Tier memory tier = allTiers[_tierId];
        TierInfo memory tierInfo = allTiersInfo[_tierId];

        require(tier.id == _tierId, "Invalid tier");

        // Get tier total supplys and counts
        uint256 tierSupply = tierInfo.totalSupply;
        uint256 tierCount = tierCounts[tier.id];

        return tierSupply.sub(tierCount);
    }

    function setPaymentAddress(address _address) public onlyOwner {
        paymentAddress = _address;
    }

    function setSignerAddress(address _address) public onlyOwner {
        signerAddress = _address;
    }

    // Set royalty wallet address
    function setRoyaltyAddress(address _address) public onlyOwner {
        royaltyAddress = _address;
    }

    // Set royalty basis points
    function setRoyaltyBasisPoints(uint256 _basisPoints) public onlyOwner {
        royaltyBasisPoints = _basisPoints;
        emit RoyaltyBasisPoints(_basisPoints);
    }

    // Set base URI
    function setBaseURI(string memory _uri) public onlyOwner {
        baseTokenURI = _uri;
    }

    function setBaseURIForMetadata(string memory _uri) public onlyOwner {
        baseTokenURIForMetadata = _uri;
    }

    // Append token metadata
    function appendTokenMetadata(uint256 _tokenId, bytes32 _metadataHash)
        public
        onlyOwner
    {
        require(_exists(_tokenId), "Nonexistent token");

        tokenMetadata[_tokenId].push(_metadataHash);
    }

    // Get all token metadata changes
    function getTokenMetadata(uint256 _tokenId)
        public
        view
        returns (bytes32[] memory)
    {
        require(_exists(_tokenId), "Nonexistent token");

        return tokenMetadata[_tokenId];
    }

    // Token URI (baseTokenURI + tokenId)
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Nonexistent token");

        uint256 tokenMetadataLength = tokenMetadata[_tokenId].length;

        if (tokenMetadataLength > 0) {
            uint256 _lastMetadataHash = uint256(
                tokenMetadata[_tokenId][tokenMetadataLength - 1]
            );

            // IPFS CID V1 is too long for Solidity byte32 but it contains the same prefix "f01551220" if it was added to IPFS with the same codec and hash function.
            // IPFS CID V1 Multihash example: bafkreif7gr5yvy5p65nbozy7o3f7m2tt2jkyhp5fgpd4cg5ljl4e7ohxxq
            // Explorer: https://cid.ipfs.io/#bafkreif7gr5yvy5p65nbozy7o3f7m2tt2jkyhp5fgpd4cg5ljl4e7ohxxq
            // It's prefix (f01551220) + SHA256 hash (BF347B8AE3AFF75A17671F76CBF66A73D25583BFA533C7C11BAB4AF84FB8F7BC)
            // List of codes: https://github.com/multiformats/multicodec/blob/master/table.csv
            // Prefix format: IPFS specific byte (f) + CID V1 (01) + multicodec code (0x55 for raw) + hash function code (0x12 for SHA256) + length (0x20 for 256-bits)
            // Final: f017012200C39FEAEE65382EFEDE80ED763CC922B280AE2A2A403C24FEE73B36D8A6AC7F7
            // Addressable as usual: http://ipfs.io/ipfs/f015512200874F3B3FEE8BFE197A86AB9F676F6246248B8FFE1F81111D1C44B11D41173CD
            // That way we can strip meaningless for blockchain "f01701220" and save huge amount of gas by storing it efficiently in byte32.
            // IMPORTANT: JSON files up to 256KB always have 0x55 (raw) codec.

            return
                string(
                    abi.encodePacked(
                        abi.encodePacked(baseTokenURIForMetadata, IPFS_PREFIX),
                        uintToHexString(_lastMetadataHash, 32)
                    )
                );
        }
        return
            string(abi.encodePacked(_baseURI(), "token/", _tokenId.toString()));
    }

    // Contract metadata URI - Support for OpenSea: https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), "contract"));
    }

    // Override supportsInterface - See {IERC165-supportsInterface}
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    // Pauses all token transfers - See {ERC721Pausable}
    function pause() public virtual onlyOwner {
        _pause();
    }

    // Unpauses all token transfers - See {ERC721Pausable}
    function unpause() public virtual onlyOwner {
        _unpause();
    }

    //-- Private Functions --/

    // Hash transaction
    function hashTransaction(
        address _sender,
        uint256 _amount,
        string memory _nonce
    ) private pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(_sender, _amount, _nonce))
            )
        );

        return hash;
    }

    // Match address signer
    function matchAddressSigner(bytes32 _hash, bytes memory _signature)
        private
        view
        returns (bool)
    {
        return signerAddress == _hash.recover(_signature);
    }

    //-- Internal Functions --//

    // Get base URI
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    // Before all token transfer
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        // Store token last transfer timestamp by id
        tokenLastTransferredAt[_tokenId] = block.timestamp;

        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    // Uint to hex string
    function uintToHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length);

        for (uint256 i = 2 * length; i > 0; --i) {
            buffer[i - 1] = HEX_ALPHABET[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
