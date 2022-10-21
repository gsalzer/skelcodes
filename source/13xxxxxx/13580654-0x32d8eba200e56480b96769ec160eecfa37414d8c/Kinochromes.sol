// File: contracts/Base64.sol

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol



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

// File: contracts/Kinochromes.sol


pragma solidity ^0.8.9;





//  _   ___                  _                                   
// | | / (_)                | |                                  
// | |/ / _ _ __   ___   ___| |__  _ __ ___  _ __ ___   ___  ___ 
// |    \| | '_ \ / _ \ / __| '_ \| '__/ _ \| '_ ` _ \ / _ \/ __|
// | |\  \ | | | | (_) | (__| | | | | | (_) | | | | | |  __/\__ \
// \_| \_/_|_| |_|\___/ \___|_| |_|_|  \___/|_| |_| |_|\___||___/
// by junkpunkie

contract Kinochromes is ERC721, ReentrancyGuard, Ownable {
    mapping(bytes10 => bool) private hashToMinted;
    mapping(uint => bytes10) private sToDNA;
    mapping(uint => bytes10) private tokenIdToDNA;
    mapping (address => bool) private addressToWhitelist;
    mapping (address => bool) private whitelistAddrToMinted;
    bool private paused = true;
    bool private whitelistPaused = true;
    uint private randNonce = 0;
    uint private totalMinted = 0;

    constructor() ERC721("Kinochromes", "[k]") {
      bytes10 dnaOne = bytes10(abi.encodePacked(bytes1(0xFF),bytes1(0xFF),bytes1(0xFF),bytes1(0),bytes1(0),bytes1(0),bytes1(0),bytes1(0),bytes1(0),bytes1(0)));
      bytes10 dnaTwo = bytes10(abi.encodePacked(bytes1(0xFF),bytes1(0xFF),bytes1(0xFF),bytes1(0),bytes1(0),bytes1(0x09),bytes1(0),bytes1(0),bytes1(0),bytes1(0)));
      bytes5 dnaOneMinusColor = getDnaMinusColor(dnaOne);
      bytes5 dnaTwoMinusColor = getDnaMinusColor(dnaTwo);

      sToDNA[0x32] = dnaOne;
      tokenIdToDNA[0x32] = getDnaMinusColor(dnaOne);
      hashToMinted[dnaOneMinusColor] = true;

      sToDNA[0x1FF] = dnaTwo;
      tokenIdToDNA[0x1FF] = getDnaMinusColor(dnaTwo);
      hashToMinted[dnaTwoMinusColor] = true;
    }    

    // MINTING RELATED FUNCTIONS

    // Pause or unpause minting
    function setPaused(bool _paused) public nonReentrant onlyOwner {
      paused = _paused;
    }

    function addToWhitelist(address[] memory users) public onlyOwner nonReentrant {
        for (uint i = 0; i < users.length; i++) {
            addressToWhitelist[users[i]] = true;
            whitelistAddrToMinted[users[i]] = false;
        }      
    }

    // Whitelisted addresses can claim 1 until public minting opens
    function whitelistClaim() public nonReentrant {
        require (addressToWhitelist[msg.sender], "You are not on the whitelist");
        require (!whitelistAddrToMinted[msg.sender], "You have already claimed with this address");
        uint index = totalSupply();
        require(index >= 50 && index < 512, "All have been minted");
        _internalMint(index);
        whitelistAddrToMinted[msg.sender] = true;
    }

    // Owner keeps the first 50
    function ownerClaim() public nonReentrant onlyOwner {
        uint index = totalSupply();
        require(index >= 0 && index + 9 < 50, "Choose an unclaimed index between 0 and 51, inclusive");
        for (uint i = index; i < index + 10; i++) {
          _internalMint(i);
        }
    }

    // Claim for public mint
    function claim() public nonReentrant {
        require (!paused, "Minting is paused");
        uint index = totalSupply();
        require(index >= 50 && index < 512, "All have been minted");
        _internalMint(index);
    }

    function _internalMint(uint256 tokenId) private {
        tokenIdToDNA[tokenId] = generateHash(tokenId);
        _safeMint(_msgSender(), tokenId);
        totalMinted++;
    }

    function generateHash(uint256 tokenId) internal returns (bytes10) {
      // bytes10 scheme is r/g/b/background/filter/pattern/transform/shape/anim1/anim2
      // like this: 0xd0714c04020901020706
      // where d0 = red, 71 = green, 4c = blue, 04 = background, 02 = filter, etc
      bytes10 dna;
      if (tokenId == 0x32 || tokenId == 0x1FF) {
        return sToDNA[tokenId];
      } else {
          dna = bytes10(
            abi.encodePacked(
              genRandomNum(tokenId, 255), // red index 0
              genRandomNum(tokenId, 255), // green index 1
              genRandomNum(tokenId, 255), // blue index 2
              genRandomNum(tokenId, 4),   // background index 3
              genRandomNum(tokenId, 5),   // filter index 4
              genRandomNum(tokenId, 9),   // pattern index 5
              genRandomNum(tokenId, 5),   // transform index 6
              genRandomNum(tokenId, 2),   // shape index 7
              genRandomNum(tokenId, 8),   // anim1 duration index 8
              genRandomNum(tokenId, 8)    // anim2 duration index 9
            )
          );
        }

        // Colors don't matter to the uniqueness of each token, but the rest
        // of the attributes do matter.
        bytes5 dnaMinusColor = getDnaMinusColor(dna);
        // No dupes
        if (hashToMinted[dnaMinusColor]) {
          randNonce++;
          return generateHash(tokenId);
        }
        hashToMinted[dnaMinusColor] = true;
        return dna;      
    }

    function getDnaMinusColor(bytes10 dna) private pure returns (bytes5) {
      return bytes5(
          abi.encodePacked(
              dna[3], dna[4], dna[5], dna[6], dna[7], dna[8], dna[9]      
          )
      );
    }

    function totalSupply() public view returns (uint) {
      return totalMinted;
    }

    // ART FUNCTIONS

    // The main SVG generator function
    function generateSvg(uint256 tokenId) internal view returns (string memory) {
        return string(abi.encodePacked(
          '<svg width="256" height="256" version="1.1" xmlns="http://www.w3.org/2000/svg" class="s1" style="background:', buildBackground(tokenId), ';">',
          generateStyle(tokenId),
          '<defs>', buildShape(tokenId), '</defs>',
          '<g id="g" style="',tokenId % 3 == 0 ? 'transform:scale(0.7) rotate(45deg);transform-origin:50% 50%;' : '','">',
          makeArt(tokenId),
          '</g></svg>'
        ));
    }

    // Creates the <style> tag
    function generateStyle(uint256 tokenId) internal view returns (string memory) {
      string[2] memory bgColors = invertColors(tokenId);
      return string(abi.encodePacked(
        '<style>.s1{--a:rgb(', bgColors[0],
        ');--b:rgb(', bgColors[1], ');transition: all 1000ms ease;}.s1:hover {filter:',tokenId == 0x32 ? 'sepia(1)' : (tokenId == 0x1FF ? 'contrast(5)' : (tokenId % 2 == 0 ? 'invert(1)' : 'hue-rotate(-270deg)')),';}.u{animation:',toString(buildAnimationDuration(tokenId, 8)) ,'ms infinite alternate a,',toString(buildAnimationDuration(tokenId, 9)),'ms infinite alternate b;transform-origin:50% 50%;}',
        buildAnimation(tokenId),
        '@keyframes b{from{opacity: 1;}to {opacity: 0.5;}}',
        '</style>'
      ));
    }

    // This is the main shape and pattern plotting function
    function makeArt(uint256 tokenId) internal view returns (string memory) {
        string memory o;
        bytes10 DNA = tokenIdToDNA[tokenId];
        uint256 seed = getDNASeed(DNA, tokenId);
        uint256 v = 0;
        int a = 0;
        int b = 0;
        // The following loop and algorithm is taken and slightly tweaked from Autoglyphs, created by Matt Hall & John Watkinson of Larva Labs.
        // The credit for this project and for onchain generative art goes to them.
        // Read the Autoglyphs contract here: https://etherscan.io/address/0xd4e4078ca3495de5b1d4db434bebc5a986197782#code
        if (uint8(DNA[5]) > 7) {
          for (uint8 y = 0; y < 8; y++) {
              a = (2 * (int8(y) - 4) + 1);
              if (seed % 3 == 1) {
                a = -a;
              } else if (seed % 3 == 2) {
                a = abs(a);
              }
              a = a * int(seed);
              for (uint8 x = 0; x < 8; x++) {
                  b = (2 * (int8(x) - 4) + 1);
                  if (seed % 2 == 1) {
                    b = abs(b);
                  }
                  b = b * int(seed);
                  v = uint(a * b / int(0x100000000)) % ((seed % 25) + 5);
                  string memory dString = v > 12 ? string(abi.encodePacked('-', toString(v * 1000))) : toString(v * 1000);
                  
                  o = string(abi.encodePacked(
                      o,
                      createShape(DNA, x, y, dString)
                  ));
              }
          }
          // Custom Patterns
        } else {
          for (uint8 y = 0; y < 8; y++) {
            for (uint8 x = 0; x < 8; x++) {
              v = drawCustomPattern(DNA, x, y, v);
              o = string(abi.encodePacked(
                  o,
                  createShape(DNA, x, y, toString(v))
              ));
            }
          }
        }
        return o;
    }

    // This giant function contains the logic to apply animation delays
    // based on the given pattern for a tokenId
    function drawCustomPattern(bytes10 DNA, uint8 x, uint8 y, uint delay) pure internal returns (uint) {
      uint _delay = delay;
      if(DNA[5] == 0x00) {
        // simple
        _delay += 100;
      } else if (DNA[5] == 0x01) {
        // staircase
        _delay += 100;
        _delay = _delay > 800 ? 0 : _delay;
      } else if (DNA[5] == 0x02) {
        // runner
        if (_delay == 0) {
          _delay = 1000;
        }
        if (y % 2 == 0) {
          _delay = x % 2 == 0 ? _delay -= 1000 : _delay;
        } else {
          _delay = x % 2 == 0 ? _delay : _delay -= 1000;
        }
        _delay += 1000;
      } else if (DNA[5] == 0x03) {
        // cross + corners
        if ((x == 0 && y == 0) || (x == 0 && y == 7) || (x == 7 && y == 0) || (x == 7 && y == 7)) {
          _delay = 6500;
        } else if (x == 3 || x == 4 || y == 3 || y == 4) {
          _delay = 0;
        } else {
          _delay = 4000;
        }
      } else if (DNA[5] == 0x04) {
        // spiral
        if (x == 0) {
          _delay = 3500 + 500 * y;
        } else if (y == 0) {
          _delay = 3500 - 500 * x;
        } else if (y == 1) {
          if (x > 0 && x < 7) {
            _delay = 17000 - 500 * x;
          } else {
            _delay = 13500;
          }
        } else if (y == 2) {
          if (x == 1) {
            _delay = 17000;
          } else if (x == 7) {
            _delay = 13000;
          } else {
            _delay = 26000 - 500 * x;
          }
        } else if (y == 3) {
          if (x == 1) {
            _delay = 17500;
          } else if (x == 2) {
            _delay = 26000;
          } else if (x == 6) {
            _delay = 23000;
          } else if (x == 7) {
            _delay = 12500;
          } else {
            _delay = 32000 - 500 * x;
          }
        } else if (y == 4) {
          if (x == 1) {
            _delay = 18000;
          } else if (x == 2) {
            _delay = 26500;
          } else if (x == 5) {
            _delay = 29000;
          } else if (x == 6) {
            _delay = 22500;
          } else if (x == 7) {
            _delay = 12000;
          } else {
            _delay = 29500 + 500 * x;
          }
        } else if (y == 5) {
          if (x == 1) {
            _delay = 18500;
          } else if (x > 1 && x < 6) {
            _delay = 26000 + 500 * x;
          } else if (x == 6) {
            _delay = 22000;
          } else {
            _delay = 11500;
          }
        } else if (y == 6) {
          if (x != 7) {
            _delay = 18500 + 500 * x;
          } else {
            _delay = 11000;
          }
        } else if (y == 7) {
          _delay = 7000 + 500 * x;
        }
      } else if (DNA[5] == 0x05) {
        // X pattern
        if ((x == 0 && y == 0) || (x == 7 && y == 7) || (x == 0 && y == 7) || (x == 7 && y == 0)) {
          _delay = 1000;
        } else if ((x == 1 && y == 1) || (x == 6 && y == 6) || (x == 1 && y == 6) || (x == 6 && y == 1)) {
          _delay = 2000;
        } else if ((x == 2 && y == 2) || (x == 5 && y == 5) || (x == 2 && y == 5) || (x == 5 && y == 2)) {
          _delay = 3000;
        } else if ((x == 3 && y == 3) || (x == 4 && y == 4) || (x == 3 && y == 4) || (x == 4 && y == 3)) {
          _delay = 4000;
        } else {
          _delay = 0;
        }
      } else if (DNA[5] == 0x06) {
        // 10Print
        _delay = tenPrint(DNA, x, y);
      } else {
        // Squares in Squares
        if (
          (x == 0 && y == 0) || (x == 7 && y == 7) || (x == 0 && y == 7) || (x == 7 && y == 0)
          || (x == 2 && y == 2) || (x == 5 && y == 5) || (x == 2 && y == 5) || (x == 5 && y == 2)
          || ((y == 2 || y == 5) && (x > 2 && x < 6))
          || (y > 2 && y < 5) && (x == 2 || x == 5)) {
          _delay = 1000;
        } else if (y == 0 || y == 7 || x == 0 || x == 7) {
          _delay = 0;
        } else {
          _delay = 2000;
        }
      }
      return _delay;
    }

    // A custom pattern based on the 10Print algorithm.
    // See: https://10print.org/
    function tenPrint(bytes10 DNA, uint8 x, uint8 y) internal pure returns (uint) {
      uint rand = (uint(uint(uint8(DNA[x])) + uint(x) + uint(y)) % (uint(y) * 3 + 35)) % 3;
      if (rand == 0) {
        return 0;
      }
      if (rand == 1) {
        return 7000;
      }
      return 15000;
    }

    // Changes a given color by subtracting up to 98 from its RGB value, and shifts the RGB position
    // so as to create a nice gradient and to not clash with the background color
    function changeColor(bytes10 _rgb, uint position, uint8 x, uint8 y) internal pure returns (bytes1) {
        return subtractBitwise(getColor(_rgb, position > 1 ? 0 : position + 1), bytes1(uint8(x ** 2) + uint8(y ** 2)));
    }

    // Returns R, G, or B
    function getColor(bytes10 _rgb, uint position) internal pure returns (bytes1) {
        return _rgb[position];
    }    

    // Creates a shape based on the x and y coordinates, and the animation delay
    function createShape(bytes10 DNA, uint8 x, uint8 y, string memory delay) pure internal returns (string memory) {
        return string(
            abi.encodePacked(
              '<use class="u" href="#r" x="', toString(uint8(x) * 32),
              '" y="', toString(uint8(y) * 32), '" fill="rgb(',
              toString(uint8(changeColor(DNA, 0, x, y))), ',',
              toString(uint8(changeColor(DNA, 1, x, y))), ',',
              toString(uint8(changeColor(DNA, 2, x, y))),
              ')" style="animation-delay:', delay, 'ms;" />'
            )
        );
    }

    // Chooses either Square or Circle shape
    function buildShape(uint256 tokenId) internal view returns (string memory) {
      string[2] memory shapes = [
        '<rect id="r" height="32" width="32"></rect>',
        '<circle id="r" cx="16" cy="16" height="32" width="32" r="8"></circle>'
      ];
      return shapes[getAttributeAtPos(tokenId, 7)];
    }

    // TOKENURI AND ATTRIBUTE FUNCTIONS

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            bytes(
              string(
                abi.encodePacked(
                  '{"name": "', (tokenId == 0x1FF || tokenId == 0x32) ? 'Albinochrome #' : 'Kinochrome #',
                  toString(tokenId),
                  getAttributes(tokenId),
                  // These two traits are called outside of getAttributes because of Stack Too Deep errors
                  '"},{"trait_type": "Animation 1 Duration","value": "',
                  getAttributeTitleValues(tokenId, 8),
                  'ms"},{"trait_type": "Animation 2 Duration","value": "',
                  getAttributeTitleValues(tokenId, 9), 'ms"}]'
                  ',"image": "data:image/svg+xml;base64,',
                  Base64.encode(
                    bytes(generateSvg(tokenId))
                  ),
                  '"}'
                )
              )
            )
          )
        ));
    }

    // Creates the "attributes" array for tokenURI
    function getAttributes(uint256 tokenId) view internal returns (string memory) {
      return string(
        abi.encodePacked(
          '", "attributes": [',(tokenId == 0x1FF || tokenId == 0x32) ? '{"trait_type": "Special","value": "Albino"},' : '',
          '{"trait_type": "Background","value": "',
          getAttributeTitleValues(tokenId, 3),
          '"},{"trait_type": "Filter","value": "',
          getAttributeTitleValues(tokenId, 4),
          '"},{"trait_type": "Pattern","value": "',
          getAttributeTitleValues(tokenId, 5),
          '"},{"trait_type": "Transform","value": "',
          getAttributeTitleValues(tokenId, 6),
          '"},{"trait_type": "Shape","value": "',
          getAttributeTitleValues(tokenId, 7)
        )
      );
    }

    // Returns the "value" for each trait_type
    function getAttributeTitleValues(uint256 tokenId, uint8 pos) view internal returns (string memory) {
      if (pos == 3) {
        return [
          'Solid',
          'Radial Gradient',
          'Linear Gradient',
          'Conic Gradient'
        ][getAttributeAtPos(tokenId, 3)];
      }
      if (pos == 4) {
        return [
          'Hue Rotate',
          'Reverse Hue Rotate',
          'Saturate/Invert',
          'Sepia',
          'Sepia/Invert'
        ][getAttributeAtPos(tokenId, 4)];
      }
      if (pos == 5) {
        uint8 index = getAttributeAtPos(tokenId, 5);
        return index > 7 ? 'Autoglyph' : [
          'Simple',
          'Staircase',
          'Runner',
          'Cross Corners',
          'Spiral',
          'X',
          '10 Print',
          'Squares in Squares'
        ][getAttributeAtPos(tokenId, 5)];
      }
      if (pos == 6) {
        return [
          'None',
          'Shrink',
          'Grow',
          'Rotate',
          'Slideways'
          // 'Slideways (Large)'
        ][getAttributeAtPos(tokenId, 6)];
      }
      if (pos == 7) {
        return [
          'Square',
          'Circle'
        ][getAttributeAtPos(tokenId, 7)];
      }
      return [
        '1500',
        '2700',
        '5100',
        '11000',
        '15500',
        '25000',
        '32000',
        '45000'
      ][getAttributeAtPos(tokenId, pos == 8 ? 8 : 9)];
    }

    // Returns animation duration in ms
    function buildAnimationDuration(uint256 tokenId, uint8 pos) internal view returns (uint16) {
      uint16[8] memory durs = [
        1500,
        2700,
        5100,
        11000,
        15500,
        25000,
        32000,
        45000
      ];
      return durs[getAttributeAtPos(tokenId, pos)];
    }

    // Returns background style for main <svg>
    function buildBackground(uint256 tokenId) internal view returns (string memory) {
      string[4] memory backgrounds = [
        'var(--a)',
        'radial-gradient(var(--a), var(--b))',
        'linear-gradient(var(--a), var(--b))',
        'conic-gradient(var(--a), var(--b))'
      ];
      return backgrounds[getAttributeAtPos(tokenId, 3)];
    }

    // Used for background only - inverts the RGB values to make a background color for the randomized palette
    function invertColors(uint256 tokenId) internal view returns (string[2] memory) {
      bytes1 red = bytes1(getAttributeAtPos(tokenId, 0));
      bytes1 green = bytes1(getAttributeAtPos(tokenId, 1));
      bytes1 blue = bytes1(getAttributeAtPos(tokenId, 2));
      return [
        string(abi.encodePacked(toString(uint8(~red)),',', toString(uint8(~green)),',', toString(uint8(~blue)))),
        string(abi.encodePacked(toString(uint8(~green)),',', toString(uint8(~blue)),',', toString(uint8(~red))))
      ];
    }

    // Returns CSS animations used for the animation pattern
    function buildAnimation(uint256 tokenId) internal view returns (string memory) {
      string[3][5] memory filters = [
        ['hue-rotate(0deg)', 'hue-rotate(180deg)', 'hue-rotate(-180deg)'],
        ['hue-rotate(0deg)', 'hue-rotate(-90deg)', 'hue-rotate(90deg)'],
        ['saturate(1) invert(0)', 'saturate(1.8) invert(1)', 'saturate(0.5) invert(0.2)'],
        ['sepia(0)', 'sepia(0.5)', 'sepia(0.8)'],
        ['sepia(0) invert(0)', 'sepia(0.5) invert(1)', 'sepia(0.8) invert(0.6)']
      ];
      string[3][5] memory transforms = [
        ['scale(1)', 'scale(1)', 'scale(1)'],
        ['scale(1)', 'scale(0.8)', 'scale(1.2)'],
        ['scale(1)', 'scale(1.6)', 'scale(1.2)'],
        ['rotate(0deg)', 'rotate(45deg)', 'rotate(-45deg)'],
        ['translate(0)', 'translate(16px)', 'translate(-16px)']
        // ['translate(0)', 'translate(-50%)']
      ];      
      string memory o = string(
        abi.encodePacked(
          '@keyframes a{25%{filter:',
          filters[getAttributeAtPos(tokenId, 4)][0],
          ';transform:',transforms[getAttributeAtPos(tokenId, 6)][0],
          ';}50%{filter:',
          filters[getAttributeAtPos(tokenId, 4)][1],
          ';transform:',transforms[getAttributeAtPos(tokenId, 6)][1],
          ';}75%{filter:',filters[getAttributeAtPos(tokenId, 4)][0],
          ';transform:',transforms[getAttributeAtPos(tokenId, 6)][0],
          ';}100%{filter:',filters[getAttributeAtPos(tokenId, 4)][2],
          ';transform:',transforms[getAttributeAtPos(tokenId, 6)][2],';}}'
        )
      );

      return o;
    }

    // Takes in a tokenId and a "max" number as the ceiling to randomly pull
    function genRandomNum(uint256 tokenId, uint8 max) internal returns (bytes1) {
      return bytes1(randMod(tokenId, max));
    }

    // Returns the value of each attribute at a specific position
    function getAttributeAtPos(uint256 tokenId, uint8 pos) internal view returns (uint8) {
      return uint8(tokenIdToDNA[tokenId][pos]);
    }    

    // Returns a seed; a uint of the DNA that's useful for performing math
    function getDNASeed(bytes10 DNA, uint256 tokenId) internal pure returns (uint64) {
        return uint64(uint256(keccak256(abi.encodePacked(
            DNA,
            tokenId
        ))));
    }    

    // UTIL FUNCTIONS

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

    function randMod(uint256 tokenId, uint8 _modulo) internal returns(uint8) {
        // increase nonce
        randNonce++; 
        return uint8(uint256(
          keccak256(
            abi.encodePacked(
              block.difficulty,
              block.timestamp,
              msg.sender,
              randNonce,
              tokenId)
            )
          )) % _modulo;
    }

    // Taken from Autoglyphs by Larva Labs
    function abs(int n) internal pure returns (int) {
        if (n >= 0) return n;
        return -n;
    }

    function subtractBitwise(bytes1 a, bytes1 b) internal pure returns (bytes1) {
      while (b != 0) {
        bytes1 borrow = (~a) & b;
        a = a ^ b;
        b = borrow << 1;
      }
      return a;
    }
}
