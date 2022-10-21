// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts@4.4.0/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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

// File: @openzeppelin/contracts@4.4.0/utils/Counters.sol


// OpenZeppelin Contracts v4.4.0 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts@4.4.0/utils/Strings.sol


// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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

// File: @openzeppelin/contracts@4.4.0/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// File: @openzeppelin/contracts@4.4.0/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts@4.4.0/utils/Address.sol


// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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

// File: @openzeppelin/contracts@4.4.0/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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

// File: @openzeppelin/contracts@4.4.0/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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

// File: @openzeppelin/contracts@4.4.0/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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

// File: @openzeppelin/contracts@4.4.0/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/contracts@4.4.0/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

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

// File: @openzeppelin/contracts@4.4.0/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

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

// File: @openzeppelin/contracts@4.4.0/token/ERC721/ERC721.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

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
        _setApprovalForAll(_msgSender(), operator, approved);
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
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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

// File: @openzeppelin/contracts@4.4.0/token/ERC721/extensions/ERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/ERC721Enumerable.sol)

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

// File: contracts/Metarzan.sol


pragma solidity ^0.8.0;





/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}

contract Metarzan is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Base64 for bytes;

    Counters.Counter private _tokenIdCounter;

    string[] private skinC = [
        "FFFFFF",
        "A0522D",
        "8d5524",
        "FFFAFA",
        "DEB887",
        "FFF5EE",
        "593123",
        "8B4513",
        "FAEBD7",
        "eac086",
        "D2B48C",
        "242424"
    ];
    string[] private skinCN = [
        "White",
        "Sienna",
        "Brown",
        "Snow",
        "Burly Wood",
        "SeaShell",
        "Black Brown",
        "Saddle Brown",
        "Antique White",
        "Caucasian",
        "Tan",
        "Black"
    ];
    uint16[] private skinCD = [
        512,
        512,
        512,
        512,
        512,
        512,
        512,
        512,
        1024,
        1024,
        1024,
        1024
    ];

    string[] private eyes = [
        "M7,10H8V11H9V12H15V11H16V10H17V11H16V12H8V11H7Z",
        "M7,12V11H8V10H16V11H17V12H16V11H15V10H9V11H8V12Z"
    ];
    string[] private eyesC = ["5d0070", "06f006", "fc9320", "aaa000"];
    string[] private eyesCN = ["Green", "Blue", "Brown", "Black"];
    uint16[] private eyesCD = [2048, 2048, 2048, 2048];

    string[] private earrings = [
        "M3,14V13H4V14Z",
        "M20,14V13H21V14Z",
        "M3,14V13H21V14H20V13H4V14Z"
    ];
    string[] private earringsN = ["Right", "Left", "Both"];
    uint16[] private earringsD = [2544, 2544, 3104];
    string[] private earringsC = [
        "1F45FC",
        "FDD017",
        "6960EC",
        "00FFFF",
        "E41B17",
        "4AA02C",
        "F9B7FF",
        "59E817",
        "F6358A"
    ];
    string[] private earringsCN = [
        "Blue Orchid",
        "Bright Gold",
        "Blue Lotus",
        "Cyan",
        "Love Red",
        "Blossom Pink",
        "Spring Green",
        "Nebula Green",
        "Violet Red"
    ];
    uint16[] private earringsCD = [
        1024,
        1024,
        512,
        512,
        1024,
        512,
        512,
        1024,
        2048
    ];

    string[] private tattoos = [
        "M15,6V5H16V6H17V7H16V6Z",
        "M10,22V21H11V22H13V21H14V22H13V23H11V22Z",
        "M10,23V22H11V21H13V22H14V23H13V22H11V23Z",
        "M9,22V21H10V22H11V21H13V22H14V21H15V22H14V23H13V22H11V23H10V22Z",
        "M9,23V22H10V21H11V22H13V21H14V22H15V23H14V22H13V23H11V22H10V23Z"
    ];
    string[] private tattoosN = ["I", "II", "III", "IV", "V"];
    uint16[] private tattoosD = [1536, 1536, 1536, 1536, 2048];
    string[] private tattoosC = ["333333", "881111"];
    string[] private tattoosCN = ["Gray", "Blood"];
    uint16[] private tattoosCD = [6000, 2192];

    string[] private eyePatches = [
        "M4,10V8H20V10H17V9H15V10H14V12H15V13H17V12H18V10H20V14H3V16H1V14H3V13H4V11H6V12H7V13H9V12H10V10H9V9H7V10H6V11H4Z",
        "M3,10V9H21V10H19V13H13V10H11V13H5V10Z",
        "M3,10V9H21V10H19V12H18V13H14V12H13V10H11V12H10V13H6V12H5V10Z",
        "M3,9V8H21V9H11V12H10V13H9V14H8V13H7V12H6V9Z",
        "M3,9V8H21V9H18V12H17V13H16V14H15V13H14V12H13V9Z"
    ];
    string[] private eyePatchesN = [
        "Ninja",
        "Sun Glasses I",
        "Sun Glasses II",
        "Right Pirate Patch",
        "Left Pirate Patch"
    ];
    uint16[] private eyePatchesD = [2048, 1024, 2048, 1024, 2048];
    string[] private eyePatchesC = [
        "827839",
        "C35817",
        "2B65EC",
        "8C001A",
        "7D0552",
        "43C6DB",
        "FCDFFF",
        "FF00FF",
        "347C2C",
        "4B0082",
        "493D26",
        "C9BE62",
        "54C571",
        "342D7E",
        "25383C",
        "2C3539"
    ];
    string[] private eyePatchesCN = [
        "Moccasin",
        "Red Fox",
        "Ocean Blue",
        "Burgundy",
        "Plum Velvet",
        "Turquoise",
        "Cotton Candy",
        "Magenta",
        "Jungle Green",
        "Indigo",
        "Mocha",
        "Ginger Brown",
        "Zombie Green",
        "Blue Whale",
        "Dark Slate Gray",
        "Gunmetal"
    ];
    uint16[] private eyePatchesCD = [
        512,
        512,
        512,
        512,
        512,
        512,
        512,
        512,
        512,
        512,
        512,
        512,
        512,
        512,
        512,
        512
    ];

    string[] private hairs = [
        "M6,4V1H18V4Z",
        "M4,6V4H5V3H6V2H18V3H19V4H20V6H18V5H17V4H7V5H6V6Z",
        "M4,13V9H3V5H4V4H5V3H6V2H18V3H19V4H20V5H21V9H20V13H19V6H18V5H17V4H7V5H6V6H5V13Z",
        "M2,20V6H3V5H4V4H5V3H6V2H18V3H19V4H20V5H21V6H22V17H22V20H21V18H20V22H19V20H18V24H17V20H18V19H19V17H20V13H21V10H20V9H19V6H18V5H17V4H7V5H6V6H5V9H4V10H3V13H4V18H5V19H6V20H7V24H6V20H5V22H4V18H3V20H2V6Z",
        "M2,20V6H3V5H4V4H5V3H6V2H18V3H19V4H20V5H21V6H22V17H22V20H21V18H20V22H19V20H18V24H17V20H18V19H19V17H20V13H21V10H20V9H19V6H18V5H17V4H11V7H10V4H9V8H8V4H7V8H6V6H5V9H4V10H3V13H4V18H5V19H6V20H7V24H6V20H5V22H4V18H3V20H2V6Z",
        "M2,20V6H3V5H4V4H5V3H6V2H18V3H19V4H20V5H21V6H22V20H21V21H20V22H19V23H18V24H17V20H18V19H19V18H20V13H21V10H20V9H19V6H18V5H17V4H7V5H6V6H5V9H4V10H3V13H4V18H5V19H6V20H7V24H6V23H5V22H4V21H3V20Z",
        "M2,20V6H3V5H4V4H5V3H6V2H18V3H19V4H20V5H21V6H22V20H21V21H20V22H19V23H18V24H17V20H18V19H19V18H20V13H21V10H20V9H19V6H18V5H17V4H15V6H13V8H11V10H9V12H7V14H5V16H4V18H5V19H6V20H7V24H6V23H5V22H4V21H3V20Z"
    ];
    string[] private hairsN = [
        "Classic Fade",
        "High Fade",
        "Pompadour",
        "Long Pushed Back",
        "Tarzan Cut",
        "Hockey",
        "Macho Long"
    ];
    uint16[] private hairsD = [256, 256, 512, 1024, 2048, 2048, 2048];
    string[] private hairsC = [
        "000000",
        "625D5D",
        "EDDA74",
        "616D7E",
        "806517",
        "F0FFFF",
        "FFF8C6",
        "C68E17",
        "835C3B",
        "FFD801",
        "7E3817",
        "EBDDE2"
    ];
    string[] private hairsCN = [
        "Black",
        "Carbon Gray",
        "Goldenrod",
        "Jet Gray",
        "Oak Brown",
        "Azure",
        "Lemon Chiffon",
        "Caramel",
        "Brown Bear",
        "Golden",
        "Sangria",
        "Lavender Pinocchio"
    ];
    uint16[] private hairsCD = [
        1536,
        768,
        512,
        512,
        768,
        512,
        512,
        768,
        512,
        512,
        768,
        512
    ];

    string[] private hats = [
        "XXX",
        "M3,8V4H4V3H5V2H6V1H7V0H17V1H18V2H19V3H20V4H21V8Z",
        "M3,6V4H5V0H19V4H21V6Z",
        "M1,5V6H20V1H4V5Z"
    ];
    string[] private hatsN = ["None", "Beret", "Panama", "Cap"];
    uint16[] private hatsD = [4096, 1024, 2048, 1024];
    string[] private hatsC = [
        "893BFF",
        "7D0541",
        "4C787E",
        "483C32",
        "9E7BFF",
        "AF9B60",
        "4863A0",
        "736AFF",
        "483C32",
        "000080",
        "800517"
    ];
    string[] private hatsCN = [
        "Aztech Purple",
        "Plum Pie",
        "Beetle Green",
        "Taupe",
        "Purple Mimosa",
        "Bullet Shell",
        "Steel Blue",
        "Light Slate Blue",
        "Sunrise Orange",
        "Navy Blue",
        "Firebrick"
    ];
    uint16[] private hatsCD = [
        1024,
        512,
        768,
        512,
        768,
        1024,
        768,
        512,
        768,
        1024,
        512
    ];

    string[] private beard = [
        "M9,19V16H15V19H14V17H10V19Z",
        "M9,20V16H15V20H14V17H10V18H13V19H11V18H10V20Z",
        "M9,20V16H15V21H14V22H13V23H11V22H10V21H9V20H11V18H13V20H14V17H10V20Z",
        "M9,20H7V19H6V18H5V15H6V16H7V17H9V16H15V17H17V16H18V15H19V18H18V19H17V20H15V21H14V22H13V23H11V22H10V21H9V20H11V18H13V20H14V17H10V20Z",
        "M10,17H7V16H6V15H5V18H6V19H7V20H8V21H16V20H17V19H18V18H19V15H18V16H17V17H15V16H9V17H14V19H13V18H11V19H10V17Z",
        "M10,17H7V16H6V15H5V14H4V19H5V20H6V21H7V22H9V23H11V24H13V23H15V22H17V21H18V20H19V19H20V14H19V15H18V16H17V17H15V16H9V17H14V18H10V17Z"
    ];
    string[] private beardN = [
        "Fu Manchu",
        "Zappa",
        "Van Dyke",
        "Ducktail",
        "Boxed",
        "Full Untouched"
    ];
    uint16[] private beardD = [1024, 768, 768, 1792, 2048, 1792];
    string[] private beardC = [
        "F0FFFF",
        "806517",
        "FFF8C6",
        "000000",
        "EDDA74",
        "616D7E",
        "625D5D",
        "FFD801",
        "C68E17",
        "835C3B",
        "7E3817",
        "EBDDE2"
    ];
    string[] private beardCN = [
        "Azure",
        "Oak Brown",
        "Lemon Chiffon",
        "Black",
        "Goldenrod",
        "Jet Gray",
        "Carbon Gray",
        "Golden",
        "Caramel",
        "Brown Bear",
        "Sangria",
        "Lavender Pinocchio"
    ];
    uint16[] private beardCD = [
        768,
        768,
        768,
        768,
        256,
        768,
        768,
        768,
        768,
        256,
        768,
        768
    ];

    function getTrait(uint256 tokenId, uint16[] memory traitD)
        private
        pure
        returns (uint256)
    {
        uint leapfrog = tokenId * 256;
        uint256 tokenHash = uint256(keccak256(bytes(leapfrog.toString()))) %
            8192;
        uint i = 0;
        uint256 currentBound = traitD[i];
        while (tokenHash > currentBound) {
            i++;
            currentBound += traitD[i];
        }
        return i;
    }

    function genFace(uint256 tokenId)
        private
        view
        returns (string memory, string memory)
    {
        uint256 selectedTrait = getTrait(tokenId, skinCD);
        string memory svg = string(
            abi.encodePacked(
                '<path d="M5,6H6V5H7V4H17V5H18V6H19V18H18V19H17V20H16V24H8V20H7V19H6V18H5Z" fill="#',
                skinC[selectedTrait],
                '" />',
                '<path d="M8,24V20H7V19H6V18H5V6H6V5H7V4H17V5H18V6H19V18H18V19H17V20H16V24H17V20H18V19H19V18H20V13H21V9H20V6H19V5H18V4H17V3H7V4H6V5H5V6H4V9H3V13H4V18H5V19H6V20H7V24Z" fill="#333" />',
                '<path d="M7,13V12H6V11H5V10H7V9H9V10H10V11H11V12H13V11H14V10H15V9H17V10H19V11H18V12H17V13H15V12H9V13Z" fill="#DDD"/>',
                '<path d="M12,16H11V15H13V16H12V17H14V18H10V17H12V16Z" fill="#333"/>'
            )
        );
        string memory trait = string(
            abi.encodePacked(
                '{"trait_type":"Skin","value":"',
                skinCN[selectedTrait],
                '"}'
            )
        );
        return (svg, trait);
    }

    function genEyes(uint256 tokenId)
        private
        view
        returns (string memory, string memory)
    {
        string memory svg;
        uint256 selectedTrait = getTrait(tokenId, eyesCD);
        string memory eyesColorSet = eyesC[selectedTrait];
        bytes memory eyesColorSetBytes = bytes(eyesColorSet);
        string memory firstEyesColor = string(
            abi.encodePacked(
                eyesColorSetBytes[0],
                eyesColorSetBytes[1],
                eyesColorSetBytes[2]
            )
        );
        string memory secondEyesColor = string(
            abi.encodePacked(
                eyesColorSetBytes[3],
                eyesColorSetBytes[4],
                eyesColorSetBytes[5]
            )
        );
        svg = string(
            abi.encodePacked(
                '<path d="',
                eyes[0],
                '" fill="#',
                firstEyesColor,
                '" />',
                '<path d="',
                eyes[1],
                '" fill="#',
                secondEyesColor,
                '" />'
            )
        );
        string memory trait = string(
            abi.encodePacked(
                '{"trait_type":"Eyes","value":"',
                eyesCN[selectedTrait],
                '"}'
            )
        );
        return (svg, trait);
    }

    function genEarrings(uint256 tokenId)
        private
        view
        returns (string memory, string memory)
    {
        string memory svg;
        string memory trait;
        uint selectedTrait = getTrait(tokenId, earringsD);
        uint selectedTraitColor = getTrait(tokenId, earringsCD);
        svg = string(
            abi.encodePacked(
                '<path d="',
                earrings[selectedTrait],
                '" fill="#',
                earringsC[selectedTraitColor],
                '" />'
            )
        );
        trait = string(
            abi.encodePacked(
                '{"trait_type":"Earring","value":"',
                earringsCN[selectedTraitColor],
                " ",
                earringsN[selectedTrait],
                '"}'
            )
        );
        return (svg, trait);
    }

    function genTattoos(uint256 tokenId)
        private
        view
        returns (string memory, string memory)
    {
        string memory svg;
        string memory trait;
        uint selectedTrait = getTrait(tokenId, tattoosD);
        uint selectedTraitColor = getTrait(tokenId, tattoosCD);
        svg = string(
            abi.encodePacked(
                '<path d="',
                tattoos[selectedTrait],
                '" fill="#',
                tattoosC[selectedTraitColor],
                '" />'
            )
        );
        trait = string(
            abi.encodePacked(
                '{"trait_type":"Tattoo","value":"',
                tattoosCN[selectedTraitColor],
                " ",
                tattoosN[selectedTrait],
                '"}'
            )
        );
        return (svg, trait);
    }

    function genEyePatches(uint256 tokenId)
        private
        view
        returns (string memory, string memory)
    {
        string memory svg;
        string memory trait;
        uint selectedTrait = getTrait(tokenId, eyePatchesD);
        uint selectedTraitColor = getTrait(tokenId, eyePatchesCD);
        svg = string(
            abi.encodePacked(
                '<path d="',
                eyePatches[selectedTrait],
                '" fill="#',
                eyePatchesC[selectedTraitColor],
                '" />'
            )
        );

        trait = string(
            abi.encodePacked(
                '{"trait_type":"Eyepatch","value":"',
                eyePatchesCN[selectedTraitColor],
                " ",
                eyePatchesN[selectedTrait],
                '"}'
            )
        );
        return (svg, trait);
    }

    function genHairs(uint256 tokenId)
        private
        view
        returns (string memory, string memory)
    {
        string memory svg;
        string memory trait;
        uint selectedTrait = getTrait(tokenId, hairsD);
        uint selectedTraitColor = getTrait(tokenId, hairsCD);
        svg = string(
            abi.encodePacked(
                '<path d="',
                hairs[selectedTrait],
                '" fill="#',
                hairsC[selectedTraitColor],
                '" />'
            )
        );
        trait = string(
            abi.encodePacked(
                '{"trait_type":"Hair","value":"',
                hairsCN[selectedTraitColor],
                " ",
                hairsN[selectedTrait],
                '"}'
            )
        );
        return (svg, trait);
    }

    function genHats(uint256 tokenId)
        private
        view
        returns (string memory, string memory)
    {
        string memory svg;
        string memory trait;
        uint selectedTrait = getTrait(tokenId, hatsD);
        if (keccak256("XXX") != keccak256(bytes(hats[selectedTrait]))) {
            uint selectedTraitColor = getTrait(tokenId, hatsCD);
            svg = string(
                abi.encodePacked(
                    '<path d="',
                    hats[selectedTrait],
                    '" fill="#',
                    hatsC[selectedTraitColor],
                    '" />'
                )
            );
            trait = string(
                abi.encodePacked(
                    '{"trait_type":"Hat","value":"',
                    hatsCN[selectedTraitColor],
                    " ",
                    hatsN[selectedTrait],
                    '"}'
                )
            );
        } else {
            svg = "";
            trait = string(
                abi.encodePacked(bytes('{"trait_type":"Hat","value":"None"}'))
            );
        }
        return (svg, trait);
    }

    function genBeard(uint256 tokenId)
        private
        view
        returns (string memory, string memory)
    {
        string memory svg;
        string memory trait;
        uint selectedTrait = getTrait(tokenId, beardD);
        uint selectedTraitColor = getTrait(tokenId, beardCD);
        svg = string(
            abi.encodePacked(
                '<path d="',
                beard[selectedTrait],
                '" fill="#',
                beardC[selectedTraitColor],
                '" />'
            )
        );
        trait = string(
            abi.encodePacked(
                '{"trait_type":"Beard","value":"',
                beardCN[selectedTraitColor],
                " ",
                beardN[selectedTrait],
                '"}'
            )
        );
        return (svg, trait);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: Deed does not exist!");
        string memory partialSVG;
        string memory partialAttributes;
        string
            memory svg = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" shape-rendering="crispEdges" viewBox="0 0 24 24">';
        string memory attributes = "[";
        (partialSVG, partialAttributes) = genFace(tokenId);
        attributes = string(
            abi.encodePacked(attributes, partialAttributes, ",")
        );
        svg = string(abi.encodePacked(svg, partialSVG));
        (partialSVG, partialAttributes) = genEyes(tokenId);
        attributes = string(
            abi.encodePacked(attributes, partialAttributes, ",")
        );
        svg = string(abi.encodePacked(svg, partialSVG));
        (partialSVG, partialAttributes) = genEarrings(tokenId);
        attributes = string(
            abi.encodePacked(attributes, partialAttributes, ",")
        );
        svg = string(abi.encodePacked(svg, partialSVG));
        (partialSVG, partialAttributes) = genTattoos(tokenId);
        attributes = string(
            abi.encodePacked(attributes, partialAttributes, ",")
        );
        svg = string(abi.encodePacked(svg, partialSVG));
        (partialSVG, partialAttributes) = genEyePatches(tokenId);
        attributes = string(
            abi.encodePacked(attributes, partialAttributes, ",")
        );
        svg = string(abi.encodePacked(svg, partialSVG));
        (partialSVG, partialAttributes) = genHairs(tokenId);
        attributes = string(
            abi.encodePacked(attributes, partialAttributes, ",")
        );
        svg = string(abi.encodePacked(svg, partialSVG));
        (partialSVG, partialAttributes) = genHats(tokenId);
        attributes = string(
            abi.encodePacked(attributes, partialAttributes, ",")
        );
        svg = string(abi.encodePacked(svg, partialSVG));
        (partialSVG, partialAttributes) = genBeard(tokenId);
        attributes = string(abi.encodePacked(attributes, partialAttributes));
        svg = string(abi.encodePacked(svg, partialSVG));

        svg = string(abi.encodePacked(svg, "</svg>"));
        attributes = string(abi.encodePacked(attributes, "]"));

        string memory _tokenURI = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{"name": "Metarzan #',
                        tokenId.toString(),
                        '", "description": "Metarzan is building a Metaverse FULLY Onchain! All the metadata and images are generated and stored 100% on-chain. No IPFS, no API. Merely Ethereum blockchain.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg)),
                        '","attributes":',
                        attributes,
                        "}"
                    )
                )
            )
        );
        return _tokenURI;
    }

    function safeMint() public nonReentrant {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < 7680);
        _tokenIdCounter.increment();
        _safeMint(_msgSender(), tokenId);
    }

    function safeMintOwner(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > 7679 && tokenId < 8192);
        _safeMint(owner(), tokenId);
    }

    constructor() ERC721("Metarzan", "MTRZN") Ownable() {}
}
