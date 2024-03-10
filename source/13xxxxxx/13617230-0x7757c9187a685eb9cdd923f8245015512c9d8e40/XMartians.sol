// SPDX-License-Identifier: MIT.
pragma solidity 0.8.7;

/**
ERROR TABLE (saves gas and contract size)
    ER1:    Ownable: caller is not the owner
    ER2: "Ownable: new owner is the zero address"
    ER3: "Address: insufficient balance"
    ER4: "Address: unable to send value, recipient may have reverted"
    ER5: "Address: low-level call failed"
    ER6: "Address: low-level call with value failed"
    ER7: "Address: insufficient balance for call"
    ER8: "Address: call to non-contract"
    ER9: "Address: low-level static call failed"
    ER10: "Address: static call to non-contract"
    ER11: "Address: low-level delegate call failed"
    ER12: "Address: delegate call to non-contract"
    ER13: "Strings: hex length insufficient"
    ER14: "ERC721: balance query for the zero address"
    ER15: "ERC721: owner query for nonexistent token"
    ER16: ERC721Metadata: URI query for nonexistent token
    ER17: ERC721: approval to current owner
    ER18: ERC721: approve caller is not owner nor approved for all
    ER19: ERC721: approved query for nonexistent token
    ER20: ERC721: approve to caller
    ER21: ERC721: transfer caller is not owner nor approved
    ER22: ERC721: transfer caller is not owner nor approved
    ER23: ERC721: transfer to non ERC721Receiver implementer
    ER24: ERC721: operator query for nonexistent token
    ER25: ERC721: transfer to non ERC721Receiver implementer
    ER26: ERC721: mint to the zero address
    ER27: ERC721: token already minted
    ER28: ERC721: transfer of token that is not own
    ER29: ERC721: transfer to the zero address
    ER30: ERC721: transfer to non ERC721Receiver implementer
    ER31: ERC721Enumerable: owner index out of bounds
    ER32: ERC721Enumerable: global index out of bounds
    ER33: insufficient funds
    ER34: XMartianNFT: checkMintQty() Exceeds Max Mint QTY
    ER35: the contract is paused
    ER36: max NFT limit exceeded for collection
    ER37: max NFT limit exceeded for collection
    ER38: max NFT limit exceeded
    ER39: ERC721Metadata: URI query for nonexistent token
/



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
        require(owner() == _msgSender(), "ER0");
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
        require(newOwner != address(0), "ER2");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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
        require(address(this).balance >= amount, "ER3");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ER4");
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
        return functionCall(target, data, "ER5");
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
        return functionCallWithValue(target, data, value, "ER6");
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
        require(address(this).balance >= value, "ER7");
        require(isContract(target), "ER8");

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
        return functionStaticCall(target, data, "ER9");
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
        require(isContract(target), "ER10");

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
        return functionDelegateCall(target, data, "ER11");
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
        require(isContract(target), "ER12");

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
        require(value == 0, "ER13");
        return string(buffer);
    }
}

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
        require(owner != address(0), "ER14");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ER15");
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
        require(_exists(tokenId), "ER16");

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
        require(to != owner, "ER17");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ER18"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ER19");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ER20");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ER21");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ER22");
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
        require(_checkOnERC721Received(from, to, tokenId, _data), "ER23");
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
        require(_exists(tokenId), "ER24");
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
            "ER25"
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
        require(to != address(0), "ER26");
        require(!_exists(tokenId), "ER27");

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
        require(ERC721.ownerOf(tokenId) == from, "ER28");
        require(to != address(0), "ER29");

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
                    revert("ER30");
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
        require(index < ERC721.balanceOf(owner), "ER31");
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
        require(index < ERC721Enumerable.totalSupply(), "ER32");
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



contract XMartians is ERC721Enumerable, Ownable {
    using Strings for uint256;

    /*
        1st mint cost payment split:
               0 15% to 0xd00f26915108dF339BF9B63Bd34a305052EefffB
               1 15% to 0x1fF99B8Ba496DCa54Dcf2dC923445B889cc08800
               2 10% to surgeReleif temp wallet 0xcd00e0cA451967560cD492d4f7e35DCdc4B8D08f
               3 29% to 0x9DCc8aac81d41FCB1e94461C55Ad23DC74b4b8FC nftPumps
               4 30% to 0xa1Dc531aA00F24665d06Ee7d3614C502c08DD964
               5 1% to 0xf1a455e6b5BA2303E37b81B258AF9D0110bCd700 iceCreamMan;

        Transfer fee split for resales:
            50% xMoony 0xd00f26915108dF339BF9B63Bd34a305052EefffB
            50% to 0xa1Dc531aA00F24665d06Ee7d3614C502c08DD964
    */
    
    uint16 public maxMintQty = 60;
    uint16 public constant MAX_SUPPLY = 10_000;
    bool public autoFloor = true;
    bool public paused = true;

    string public baseExtension = ".json";
    string public placeHolderURL;
    string[] public baseURIs;

    /**
        @notice currentCollectionSupply holds current supply of each collection
        @notice currentCollectionSupply[COLLECTION NUMBER] = CURRENT QTY MINTED IN COLLECTION
        @dev currentCollectionSupply[0] galaxy supply
        @dev currentCollectionSupply[1] nebula supply
        @dev currentCollectionSupply[2] superNova supply
        @dev currentCollectionSupply[3] hyperRare supply
        @dev currentCollectionSupply[4] custom supply
     */
    mapping(uint8 => uint32) public currentSubCollectionSupply;

    /**
        @notice cost holds current cost to mint an item from each subCollection
        @notice cost[COLLECTION NUMBER] = mint cost
        @dev cost[0] galaxy cost
        @dev cost[1] nebula cost
        @dev cost[2] superNova cost
        @dev cost[3] hyperRare cost
        @dev cost[4] custom cost
     */
    mapping(uint8 => uint256) public cost;

    /**
        @notice maxSubCollectionMints holds MAX mintable for the sub collection
        @notice maxSubCollectionMints[COLLECTION NUMBER] = mint cost
        @dev maxSubCollectionMints[0] galaxy cost
        @dev maxSubCollectionMints[1] nebula cost
        @dev maxSubCollectionMints[2] superNova cost
        @dev maxSubCollectionMints[3] hyperRare cost
        @dev maxSubCollectionMints[4] custom cost
     */
     
    
    mapping(uint8 => uint16) public maxSubCollectionMints;
    mapping(uint256 => uint8) public addressUrlType;
    mapping(uint256 => uint256) public urlToId;
    mapping(uint256 => string) public idUrlCustom;

    // USAGE: customMintables[address] = customMintableNFTS
    mapping(address => uint8) public customMintables;

    // USAGE: giveAwayAllowance[subCollectionNumber][address] = number address can claim
    mapping(uint8 => mapping(address => uint8)) public giveAwayAllowance;
    // USAGE: remainingReserved[subCollectionNumber] = number of remaining items reserved for presale addresses
    mapping(uint8 => uint16) public remainingReserved; 
    // USAGE: holderReservedCount[subCollectionNumber][address] = number of reserved items for address
    mapping(uint8 => mapping(address => uint16)) public holderReservedCount;

    //galaxy 0
    //nebula 1
    //superNova 2
    //hyper 3

    function batchAddCustomMintables(
        address[] memory addr,
        uint8[] memory count
    ) external onlyOwner {
        /*
        checkEqualListLengths(
            uint16(addr.length),
            uint16(count.length),
            uint16(count.length)
        );
        */
        _iterateBatchAddCustomMintables(addr, count);
    }
    
    function _iterateBatchAddCustomMintables(
        address[] memory addr,
        uint8[] memory count
    ) internal {
        for (uint16 i = 0; i < addr.length; i++) {
            customMintables[addr[i]] = count[i];
        }
    }

    function batchAddGiveAwayAllowance(
        address[] memory addr,
        uint8[] memory count,
        uint8[] memory collectionNumber
    ) external onlyOwner {
        /*
        checkEqualListLengths(
            uint16(addr.length),
            uint16(count.length),
            uint16(collectionNumber.length)
        );
        */
        _iterateBatchAddToGiveAway(addr,count,collectionNumber);
    }
    
    function _iterateBatchAddToGiveAway(
        address[] memory addr,
        uint8[] memory count,
        uint8[] memory collectionNumber
    ) internal {
        for (uint16 i = 0; i < addr.length; i++) {
            giveAwayAllowance[collectionNumber[i]][addr[i]] = count[i];
        }
    }

    function batchAddHolderReservedCount(
        address[] memory addr,
        uint8[] memory count,
        uint8[] memory collectionNumber
    ) external onlyOwner {
        /*
        checkEqualListLengths(
            uint16(addr.length),
            uint16(count.length),
            uint16(collectionNumber.length)
        );
        */
        _iterateBatchAddHolderReservedCount(addr,count,collectionNumber);
    }
    
    function _iterateBatchAddHolderReservedCount(
        address[] memory addr,
        uint8[] memory count,
        uint8[] memory collectionNumber
    ) internal {
        for (uint16 i = 0; i < addr.length; i++) {
            holderReservedCount[collectionNumber[i]][addr[i]] = count[i];
            remainingReserved[collectionNumber[i]] = remainingReserved[collectionNumber[i]] + count[i];
        }
    }
    
    constructor(
        string memory _name,
        string memory _symbol,
        string[] memory _initBaseURIs,
        string memory _placeHolderURL
    ) ERC721(_name, _symbol) {
        setBaseURIs(_initBaseURIs);
        placeHolderURL = _placeHolderURL;

        cost[0] = 0.02 ether;
        cost[1] = 0.03 ether;
        cost[2] = 0.04 ether;
        cost[3] = 0.05 ether;
        cost[4] = 0.00 ether;

        maxSubCollectionMints[0] = 5700;
        maxSubCollectionMints[1] = 2500;
        maxSubCollectionMints[2] = 1450;
        maxSubCollectionMints[3] = 150;
        maxSubCollectionMints[4] = 200;
    }

  // internal
    function _baseURIs() public view virtual returns (string[] memory) {
        return baseURIs;
    }

    function mintGalaxy(uint8 mintQty) public payable { _iterateMint(0, mintQty); }
    function mintNebula(uint8 mintQty) public payable { _iterateMint(1, mintQty); }
    function mintSuperNova(uint8 mintQty) public payable { _iterateMint(2, mintQty); }
    function mintHyperRare(uint8 mintQty) public payable { _iterateMint(3, mintQty); }
    function mintCustom() public payable { _mintCustom(); }

  // public
    function _iterateMint(uint8 subCollection, uint8 mintQty) internal {
        checkPaused();
        checkMintQty(mintQty, maxMintQty);
        uint256 _afterMintSupply = totalSupply() + mintQty;
        checkMaxSupply(_afterMintSupply);
        checkSupplyAndReserved(subCollection, mintQty);
        //update cost
        if(autoFloor){ _updateAutoFloorPrice(); }

        // if the msgSender has a free giveaway allowance
        if(mintQty <= giveAwayAllowance[subCollection][_msgSender()]){
            // subtract mint qty from giveAway allowance
            giveAwayAllowance[subCollection][_msgSender()] - mintQty;
        } else {
            checkTxCost(msg.value, (cost[subCollection] * mintQty));
        }

        for (uint256 i; i < mintQty; i++) {
            _mintTx(subCollection);
        }
    }

    function getTxCost(uint8 subCollection, uint8 mintQty) public view returns (uint256 value){
        if(mintQty <= giveAwayAllowance[subCollection][_msgSender()]){
            return 0;
        } else {
            return (cost[subCollection] * mintQty);
        }
    }


    function _mintTx(uint8 subCollection) internal {
        uint256 tokenId = totalSupply() + 1;
        addressUrlType[tokenId] = subCollection;
        currentSubCollectionSupply[subCollection]++;
        urlToId[tokenId] = currentSubCollectionSupply[subCollection];
        _safeMint(_msgSender(), tokenId);
        distributePayment();
    }

    
    function _mintCustom() internal {
        checkPaused();
        if(customMintables[_msgSender()] > 0 || _msgSender() == owner()){
            if (_msgSender() != owner()) {
                customMintables[_msgSender()]--;
                require(msg.value >= cost[4] , "insufficient funds");
            }
            uint256 tokenId = totalSupply() + 1;
            currentSubCollectionSupply[4]++;
            addressUrlType[tokenId] = 4;
            _safeMint(_msgSender(), tokenId);
            idUrlCustom[tokenId] = placeHolderURL;
        }
    }

    function _updateAutoFloorPrice() internal {
        uint256 _totalSupply = totalSupply();
        if(_totalSupply > 1000) { _setPrice(0.022 ether, 0.033 ether, 0.044 ether, 0.055 ether); }
        else if(_totalSupply > 2000) { _setPrice(0.0242 ether, 0.0363 ether, 0.0484 ether, 0.0605 ether); }
        else if(_totalSupply > 3000) { _setPrice(0.0266 ether, 0.0399 ether, 0.0532 ether, 0.0666 ether); }
        else if(_totalSupply > 4000) { _setPrice(0.0293 ether, 0.0439 ether, 0.0585 ether, 0.0733 ether); }
        else if(_totalSupply > 5000) { _setPrice(0.0322 ether, 0.0483 ether, 0.0644 ether, 0.0806 ether); }
        else if(_totalSupply > 6000) { _setPrice(0.0354 ether, 0.0531 ether, 0.0708 ether, 0.0887 ether); }
        else if(_totalSupply > 7000) { _setPrice(0.0389 ether, 0.0584 ether, 0.0779 ether, 0.0976 ether); }
        else if(_totalSupply > 8000) { _setPrice(0.0428 ether, 0.0642 ether, 0.0857 ether, 0.1074 ether); }
        else if(_totalSupply > 8000) { _setPrice(0.0471 ether, 0.0706 ether, 0.0943 ether, 0.1181 ether); }
    }

    function _setPrice(
        uint256 costSubCol0,
        uint256 costSubCol1,
        uint256 costSubCol2,
        uint256 costSubCol3
    ) internal {
        cost[0] = costSubCol0;
        cost[1] = costSubCol1;
        cost[2] = costSubCol2;
        cost[3] = costSubCol3;
     }

    function setPrice(
        uint256 galaxyCost_,
        uint256 nebulaCost_,
        uint256 superNovaCost_,
        uint256 hyperRareCost_,
        uint256 customCost_
    ) external onlyOwner {
        cost[0] = galaxyCost_;
        cost[1] = nebulaCost_;
        cost[2] = superNovaCost_;
        cost[3] = hyperRareCost_;
        cost[4] = customCost_;
    }
    
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
          tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ER39"
        );

        string[] memory currentBaseURI = _baseURIs();
        if (addressUrlType[tokenId] == 4) {
            return bytes(idUrlCustom[tokenId]).length > 0
                ? string(abi.encodePacked(idUrlCustom[tokenId], baseExtension))
                : "";
        } else {
            return bytes(currentBaseURI[addressUrlType[tokenId]]).length > 0
                ? string(abi.encodePacked(currentBaseURI[addressUrlType[tokenId]], urlToId[tokenId].toString(), baseExtension))
                : "";
        }
    }

    //only owner
    function togglePaused() external onlyOwner {
        paused?
        paused = false:
        paused = true;
    }

    function toggleAutoFloor() external onlyOwner {
        autoFloor?
        autoFloor = false:
        autoFloor = true;
    }

    function setBaseURIs(string[] memory _newBaseURIs) public onlyOwner {baseURIs = _newBaseURIs;}
    function setMaxMintQty(uint16 new_maxMintQty) public onlyOwner {maxMintQty = new_maxMintQty;}
    function setCustomUrl(uint256 tokenId, string memory newUrl) public onlyOwner  {idUrlCustom[tokenId] = newUrl;}
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {baseExtension = _newBaseExtension;}

    // check functions with Revert statements
    function checkMaxSupply(uint256 afterMintSupply_) internal pure {
        require(afterMintSupply_ <= MAX_SUPPLY, "ER38");
    }

    function checkSupplyAndReserved(uint8 collectionNumber, uint16 mintQty) internal {
        address sender = _msgSender();
        uint16 holderReserved_ = holderReservedCount[collectionNumber][sender];
        uint16 remainingReserved_ = remainingReserved[collectionNumber];
        uint16 maxSubCollectionMints_ = maxSubCollectionMints[collectionNumber];
        if(holderReserved_ == 0) {
            require(
                currentSubCollectionSupply[collectionNumber] + mintQty <= maxSubCollectionMints_ - remainingReserved_,
                "ER36"
            );
        } else {
            require(
                currentSubCollectionSupply[collectionNumber] + mintQty <= maxSubCollectionMints_,
                "ER37"
            );
            if(mintQty >= holderReserved_) {
                remainingReserved[collectionNumber] = remainingReserved_ - holderReserved_;
                holderReservedCount[collectionNumber][sender] = 0;
            } else {
                remainingReserved[collectionNumber] = remainingReserved_ - mintQty;
                holderReservedCount[collectionNumber][sender] = holderReserved_ - mintQty;
            }
        }
    }

    function checkTxCost(uint256 msgValue, uint256 totalMintCost) internal pure {
        require(msgValue >= totalMintCost, "ER33");
    }

    function checkMintQty(uint8 mintQty, uint16 maxMintQty_) internal pure {
        require(mintQty <= maxMintQty_, "ER34");
    }

    function checkPaused() internal view {
        require(!paused || _msgSender() == owner(), "ER35");
    }

     
    function distributePayment() internal {
        uint256 splitA = address(this).balance*15/100;
        uint256 splitB = address(this).balance*15/100;
        uint256 splitC = address(this).balance*10/100;
        uint256 splitD = address(this).balance*29/100;
        uint256 splitE = address(this).balance*30/100;
        uint256 splitF = address(this).balance*1/100;

        Address.sendValue(payable(0xd00f26915108dF339BF9B63Bd34a305052EefffB), splitA);
        Address.sendValue(payable(0x1fF99B8Ba496DCa54Dcf2dC923445B889cc08800), splitB);
        Address.sendValue(payable(0xcd00e0cA451967560cD492d4f7e35DCdc4B8D08f), splitC);
        Address.sendValue(payable(0x9DCc8aac81d41FCB1e94461C55Ad23DC74b4b8FC), splitD);
        Address.sendValue(payable(0xa1Dc531aA00F24665d06Ee7d3614C502c08DD964), splitE);
        Address.sendValue(payable(0xf1a455e6b5BA2303E37b81B258AF9D0110bCd700), splitF);
    }

    function sendResalePayments() internal {
        uint256 splitA = address(this).balance*1/100;
        uint256 splitB = address(this).balance*495/1000;
        uint256 splitC = address(this).balance*495/1000;

        Address.sendValue(payable(0xf1a455e6b5BA2303E37b81B258AF9D0110bCd700), splitA);
        Address.sendValue(payable(0xd00f26915108dF339BF9B63Bd34a305052EefffB), splitB);
        Address.sendValue(payable(0xa1Dc531aA00F24665d06Ee7d3614C502c08DD964), splitC);
    }

    fallback() external payable { sendResalePayments(); }
    receive() external payable { sendResalePayments(); }
}

/**
    ["ipfs://0.","ipfs://1.","ipfs://2.","ipfs://3.","ipfs://Custom"] 
    ["0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2", "0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c"] 
    ["0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"]["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4"]
    "0x7b96aF9Bd211cBf6BA5b0dd53aa61Dc5806b6AcE"
*/
