pragma solidity ^0.5.14;

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


// File: node_modules\@openzeppelin\contracts\ownership\Ownable.sol


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
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
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

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

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
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to owner
    mapping (uint256 => address) private _tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping (address => Counters.Counter) private _ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }

    /**
     * @dev Gets the owner of the specified token ID.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved) public {
        require(to != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][to] = approved;
        emit ApprovalForAll(_msgSender(), to, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner.
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * Requires the msg.sender to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the _msgSender() to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransferFrom(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether the specified token exists.
     * @param tokenId uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID.
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     * is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Internal function to safely mint a new token.
     * Reverts if the given token ID already exists.
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Internal function to safely mint a new token.
     * Reverts if the given token ID already exists.
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     * @param _data bytes data to send along with a safe transfer check
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use {_burn} instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * This function is deprecated.
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Private function to clear current approval of a given token ID.
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

/**
 * @title ERC-721 Non-Fungible Token with optional enumeration extension logic
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Enumerable is Context, ERC165, ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Constructor function.
     */
    constructor () public {
        // register the supported interface to conform to ERC721Enumerable via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev Gets the token ID at a given index of the tokens list of the requested owner.
     * @param owner address owning the tokens list to be accessed
     * @param index uint256 representing the index to be accessed of the requested tokens list
     * @return uint256 token ID at the given index of the tokens list owned by the requested address
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract.
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev Gets the token ID at a given index of all the tokens in this contract
     * Reverts if the index is greater or equal to the total number of tokens.
     * @param index uint256 representing the index to be accessed of the tokens list
     * @return uint256 token ID at the given index of the tokens list
     */
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to transferFrom, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to address the beneficiary that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use {ERC721-_burn} instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        _removeTokenFromOwnerEnumeration(owner, tokenId);
        // Since tokenId will be deleted, we can clear its slot in _ownedTokensIndex to trigger a gas refund
        _ownedTokensIndex[tokenId] = 0;

        _removeTokenFromAllTokensEnumeration(tokenId);
    }

    /**
     * @dev Gets the list of token IDs of the requested owner.
     * @param owner address owning the tokens
     * @return uint256[] List of token IDs owned by the requested address
     */
    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
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

        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        _ownedTokens[from].length--;

        // Note that _ownedTokensIndex[tokenId] hasn't been cleared: it still points to the old slot (now occupied by
        // lastTokenId, or just over the end of the array if the token was the last one).
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ERC721Metadata is Context, ERC165, ERC721, IERC721Metadata {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /**
     * @dev Constructor function
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    /**
     * @dev Gets the token name.
     * @return string representing the token name
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol.
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }
     

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param uri string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use _burn(uint256) instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned by the msg.sender
     */
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

/**
 * @title Full ERC721 Token
 * @dev This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology.
 *
 * See https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
        // solhint-disable-previous-line no-empty-blocks
    }
}

/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <remco@2π.com>, Eenae <alexey@mixbytes.io>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor() public {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}


/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}


library RandomSalt
{
	/**
	* Initialize the pool with the entropy of the blockhashes of the blocks in the closed interval [earliestBlock, latestBlock]
	* The argument "seed" is optional and can be left zero in most cases.
	* This extra seed allows you to select a different sequence of random numbers for the same block range.
	*/
	function init(uint256 earliestBlock, uint256 latestBlock, uint256 seed) internal view returns (bytes32[] memory) {
		require(block.number-1 >= latestBlock && latestBlock >= earliestBlock, "RandomSalt.init: invalid block interval");
		bytes32[] memory pool = new bytes32[](latestBlock-earliestBlock+2);
		bytes32 salt = keccak256(abi.encodePacked(block.number,seed));
		for(uint256 i=0; i<=latestBlock-earliestBlock; i++) {
			// Add some salt to each blockhash so that we don't reuse those hash chains
			// when this function gets called again in another block.
			pool[i+1] = keccak256(abi.encodePacked(blockhash(earliestBlock+i),salt));
		}
		return pool;
	}
	
	/**
	* Initialize the pool from the latest "num" blocks.
	*/
	function initLatest(uint256 num, uint256 seed) internal view returns (bytes32[] memory) {
		return init(block.number-num, block.number-1, seed);
	}
	
	/**
	* Advances to the next 256-bit random number in the pool of hash chains.
	*/
	function next(bytes32[] memory pool) internal pure returns (uint256) {
		require(pool.length > 1, "RandomSalt.next: invalid pool");
		uint256 roundRobinIdx = uint256(pool[0]) % (pool.length-1) + 1;
		bytes32 hash = keccak256(abi.encodePacked(pool[roundRobinIdx]));
		pool[0] = bytes32(uint256(pool[0])+1);
		pool[roundRobinIdx] = hash;
		return uint256(hash);
	}
	
	/**
	* Produces random integer values, uniformly distributed on the closed interval [a, b]
	*/
	function uniform(bytes32[] memory pool, int256 a, int256 b) internal pure returns (int256) {
		require(a <= b, "RandomSalt.uniform: invalid interval");
		return int256(next(pool)%uint256(b-a+1))+a;
	}
}

library Random {
    /**
    * Initialize the pool from some seed.
    */
    function init(uint256 seed) internal pure returns (bytes32[] memory) {
        bytes32[] memory hashchain = new bytes32[](1);
        hashchain[0] = bytes32(seed);
        return hashchain;
    }
    
    /**
    * Advances to the next 256-bit random number in the pool of hash chains.
    */
    function next(bytes32[] memory hashchain) internal pure returns (uint256) {
        require(hashchain.length == 1, "Random.next: invalid param");
        hashchain[0] = keccak256(abi.encodePacked(hashchain[0]));
        return uint256(hashchain[0]);
    }
    
    /**
    * Produces random integer values, uniformly distributed on the closed interval [a, b]
    */
    function uniform_int(bytes32[] memory hashchain, int256 a, int256 b) internal pure returns (int256) {
        require(a <= b, "Random.uniform_int: invalid interval");
        return int256(next(hashchain)%uint256(b-a+1))+a;
    }
    
    /**
    * Produces random integer values, uniformly distributed on the closed interval [a, b]
    */
    function uniform_uint(bytes32[] memory hashchain, uint256 a, uint256 b) internal pure returns (uint256) {
        require(a <= b, "Random.uniform_uint: invalid interval");
        return next(hashchain)%(b-a+1)+a;
    }
}
 
library Buffer {
    function hasCapacityFor(bytes memory buffer, uint256 needed) internal pure returns (bool) {
        uint256 size;
        uint256 used;
        assembly {
            size := mload(buffer)
            used := mload(add(buffer, 32))
        }
        return size >= 32 && used <= size - 32 && used + needed <= size - 32;
    }
    
    function toString(bytes memory buffer) internal pure returns (string memory) {
        require(hasCapacityFor(buffer, 0), "Buffer.toString: invalid buffer");
        string memory ret;
        assembly {
            ret := add(buffer, 32)
        }
        return ret;
    }
    
    function append(bytes memory buffer, string memory str) internal view {
        require(hasCapacityFor(buffer, bytes(str).length), "Buffer.append: no capacity");
        assembly {
            let len := mload(add(buffer, 32))
            pop(staticcall(gas, 0x4, add(str, 32), mload(str), add(len, add(buffer, 64)), mload(str)))
            mstore(add(buffer, 32), add(len, mload(str)))
        }
    }
    
    /**
     * value must be in the closed interval [-999, 999]
     * otherwise only the last 3 digits will be converted
     */
    function numbie(bytes memory buffer, int256 value) internal pure {
        require(hasCapacityFor(buffer, 4), "Buffer.numbie: no capacity");
        assembly {
            function numbx1(x, v) -> y {
                // v must be in the closed interval [0, 9]
                // otherwise it outputs junk
                mstore8(x, add(v, 48))
                y := add(x, 1)
            }
            function numbx2(x, v) -> y {
                // v must be in the closed interval [0, 99]
                // otherwise it outputs junk
                y := numbx1(numbx1(x, div(v, 10)), mod(v, 10))
            }
            function numbu3(x, v) -> y {
                // v must be in the closed interval [0, 999]
                // otherwise only the last 3 digits will be converted
                switch lt(v, 100)
                case 0 {
                    // without input value sanitation: y := numbx2(numbx1(x, div(v, 100)), mod(v, 100))
                    y := numbx2(numbx1(x, mod(div(v, 100), 10)), mod(v, 100))
                }
                default {
                    switch lt(v, 10)
                    case 0 { y := numbx2(x, v) }
                    default { y := numbx1(x, v) }
                }
            }
            function numbi3(x, v) -> y {
                // v must be in the closed interval [-999, 999]
                // otherwise only the last 3 digits will be converted
                if slt(v, 0) {
                    v := add(not(v), 1)
                    mstore8(x, 45)  // minus sign
                    x := add(x, 1)
                }
                y := numbu3(x, v)
            }
            let strIdx := add(mload(add(buffer, 32)), add(buffer, 64))
            strIdx := numbi3(strIdx, value)
            mstore(add(buffer, 32), sub(sub(strIdx, buffer), 64))
        }
    }
    
    function hexrgb(bytes memory buffer, uint256 r, uint256 g, uint256 b) internal pure {
        require(hasCapacityFor(buffer, 6), "Buffer.hexrgb: no capacity");
        assembly {
            function hexrgb(x, r, g, b) -> y {
                let rhi := and(shr(4, r), 0xf)
                let rlo := and(r, 0xf)
                let ghi := and(shr(4, g), 0xf)
                let glo := and(g, 0xf)
                let bhi := and(shr(4, b), 0xf)
                let blo := and(b, 0xf)
                mstore8(x,         add(add(rhi, mul(div(rhi, 10), 39)), 48))
                mstore8(add(x, 1), add(add(rlo, mul(div(rlo, 10), 39)), 48))
                mstore8(add(x, 2), add(add(ghi, mul(div(ghi, 10), 39)), 48))
                mstore8(add(x, 3), add(add(glo, mul(div(glo, 10), 39)), 48))
                mstore8(add(x, 4), add(add(bhi, mul(div(bhi, 10), 39)), 48))
                mstore8(add(x, 5), add(add(blo, mul(div(blo, 10), 39)), 48))
                y := add(x, 6)
            }
            let strIdx := add(mload(add(buffer, 32)), add(buffer, 64))
            strIdx := hexrgb(strIdx, r, g, b)
            mstore(add(buffer, 32), sub(sub(strIdx, buffer), 64))
        }
    }
}
 
contract squigglyWTF is ERC721Full, Ownable, ReentrancyGuard {
    using SafeMath for uint256;    
    using Roles for Roles.Role;

    Roles.Role private _auctioneers;
    
    uint8 public totalPromoClaimants;

    mapping(uint256 => address) internal promoClaimantStorage;
    mapping(address => uint256) addressToInkAll;
    mapping(uint8 => address) inkToAddress;
    mapping(uint256 => address) idToCreator;
    mapping(uint256 => uint256) idToSVGSeed;
    mapping(uint256 => string) idToPromoSVG;

    string public squigglyGalleryLink;
    string public referenceURI;
    
    uint8 public totalInk;
    uint8 public constant maximumInk = 100;
    uint8 public constant tokenLimit = 99;
    uint256 public priceOfInk;
    bool public auctionIsLive;
    bool public priceGoUp;
    bool public priceGoDown;
    bool public auctionStarted;
    uint256 public blockTimeCounter;

    constructor() ERC721Full("Squiggly", "~~") public {

    auctionStarted = false;
    auctionIsLive = false;
    priceGoUp = false;
    priceGoDown = false;
    totalPromoClaimants = 0;
    priceOfInk = 20000000000000000;
    referenceURI = "https://squigglywtf.azurewebsites.net/api/HttpTrigger?id=";
    _auctioneers.add(0x63a9dbCe75413036B2B778E670aaBd4493aAF9F3);
    
    }    
    
    function getNumber(uint seed, int min, int max) internal view returns (int256 randomNumber){

    bytes32[] memory pool = RandomSalt.initLatest(1, seed);        
		randomNumber = RandomSalt.uniform(pool, min, max); 
    }
    
    function renderFromSeed(uint256 seed) public view returns (string memory) {
        bytes32[] memory hashchain = Random.init(seed);
        
        bytes memory buffer = new bytes(8192);
        
        uint256 curveType = Random.uniform_uint(hashchain,1,5);
        uint8 squiggleCount = uint8(curveType) + 2;
        uint stopColorBW;
        
        Buffer.append(buffer, "<svg xmlns='http://www.w3.org/2000/svg' width='640' height='640' viewBox='0 0 640 640' style='stroke-width:0; background-color:#121212;'>");
        
        // Draw squiggles. Each squiggle is a pair of <radialGradient> and <path>.
        for(int i=0; i<squiggleCount; i++) {
        
            // append the <radialGradient>
            
            Buffer.append(buffer, "<radialGradient id='grad");
            Buffer.numbie(buffer, i);
            Buffer.append(buffer, "'><stop offset='0%' style='stop-color:#");
            // gradient start color:
            Buffer.hexrgb(buffer, Random.uniform_uint(hashchain,16,255), Random.uniform_uint(hashchain,16,255), Random.uniform_uint(hashchain,16,255));
            
            Buffer.append(buffer, ";stop-opacity:0' /><stop offset='100%' style='stop-color:#");
            // gradient stop color:
            stopColorBW = Random.uniform_uint(hashchain,16,255);
            Buffer.hexrgb(buffer, stopColorBW, stopColorBW, stopColorBW);
            Buffer.append(buffer, ";stop-opacity:1' /></radialGradient>");
            
            // append the <path>
            
            Buffer.append(buffer, "<path fill='url(#grad");
            Buffer.numbie(buffer, i);
            Buffer.append(buffer, ")' stroke='#");
            // path stroke color:
            Buffer.hexrgb(buffer, Random.uniform_uint(hashchain,16,255), Random.uniform_uint(hashchain,16,255), Random.uniform_uint(hashchain,16,255));
            Buffer.append(buffer, "' stroke-width='0' d='m ");
            // path command 'm': Move the current point by shifting the last known position of the path by dx along the x-axis and by dy along the y-axis.
            Buffer.numbie(buffer, Random.uniform_int(hashchain,240,400));  // move dx
            Buffer.append(buffer, " ");
            Buffer.numbie(buffer, Random.uniform_int(hashchain,240,400));  // move dy
            
            if(curveType == 1) {
                Buffer.append(buffer, ' c');
                
                for(int j=0; j<77; j++) {
                    // path command 'c': Draw a cubic Bézier curve.
                    Buffer.append(buffer, " ");
                    Buffer.numbie(buffer, Random.uniform_int(hashchain,-77,77));  // curve dx1
                    Buffer.append(buffer, " ");
                    Buffer.numbie(buffer, Random.uniform_int(hashchain,-77,77));  // curve dy1
                    Buffer.append(buffer, " ");
                    Buffer.numbie(buffer, Random.uniform_int(hashchain,-77,77));  // curve dx2
                    Buffer.append(buffer, " ");
                    Buffer.numbie(buffer, Random.uniform_int(hashchain,-77,77));  // curve dy2
                    Buffer.append(buffer, " ");
                    Buffer.numbie(buffer, Random.uniform_int(hashchain,-77,77));  // curve dx
                    Buffer.append(buffer, " ");
                    Buffer.numbie(buffer, Random.uniform_int(hashchain,-77,77));  // curve dy
                }
                
            } else if(curveType == 2) {
                Buffer.append(buffer, " s");
                
                for(int j=0; j<91; j++) {
                    // path command 's': Draw a smooth cubic Bézier curve.
                    Buffer.append(buffer, " ");
                    Buffer.numbie(buffer, Random.uniform_int(hashchain,-69,69));  // curve dx2
                    Buffer.append(buffer, " ");
                    Buffer.numbie(buffer, Random.uniform_int(hashchain,-69,69));  // curve dy2
                    Buffer.append(buffer, " ");
                    Buffer.numbie(buffer, Random.uniform_int(hashchain,-69,69));  // curve dx
                    Buffer.append(buffer, " ");
                    Buffer.numbie(buffer, Random.uniform_int(hashchain,-69,69));  // curve dy
                }
                
            } else if(curveType == 3) {
                Buffer.append(buffer, ' q');
                
                for(int j=0; j<77; j++) {
                    // path command 'q': Draw a quadratic Bézier curve.
                    Buffer.append(buffer, " ");
                    Buffer.numbie(buffer, Random.uniform_int(hashchain,-47,47));  // curve dx1
                    Buffer.append(buffer, " ");
                    Buffer.numbie(buffer, Random.uniform_int(hashchain,-47,47));  // curve dy1
                    Buffer.append(buffer, " ");
                    Buffer.numbie(buffer, Random.uniform_int(hashchain,-47,47));  // curve dx
                    Buffer.append(buffer, " ");
                    Buffer.numbie(buffer, Random.uniform_int(hashchain,-47,47));  // curve dy
                }
                
            } else if(curveType == 4) {
                Buffer.append(buffer, ' t');
                
                for(int j=0; j<123; j++) {
                    // path command 't': Draw a smooth quadratic Bézier curve.
                    Buffer.append(buffer, " ");
                    Buffer.numbie(buffer, Random.uniform_int(hashchain,-29,29));  // curve dx
                    Buffer.append(buffer, " ");
                    Buffer.numbie(buffer, Random.uniform_int(hashchain,-29,29));  // curve dy
                }
                
            } else if(curveType == 5) {
                
                for(int j=0; j<99; j++) {
                    // no path command: No curve.
                    Buffer.append(buffer, " ");
                    Buffer.numbie(buffer, Random.uniform_int(hashchain,-37,37));  // point dx
                    Buffer.append(buffer, " ");
                    Buffer.numbie(buffer, Random.uniform_int(hashchain,-37,37));  // point dy
                }
                
            }
            
            Buffer.append(buffer, "' />");
            
        }
        
        Buffer.append(buffer, "</svg>");
        
        return Buffer.toString(buffer);
    }

    function ribbonCut() public onlyOwner {
        auctionStarted = true;
    }    

    function startAuction() public nonReentrant {
        require(auctionStarted == true);
        require(auctionIsLive == false);
        require(totalSupply() <= tokenLimit, "Squiggly sale has concluded. Good luck prying one out of the hands of someone on the secondary market.");
        priceOfInk = calculateInkValue();
        blockTimeCounter = block.timestamp + 15000;
        auctionIsLive = true;
        
        inkToAddress[0] = msg.sender;
        inkToAddress[1] = msg.sender;
        addressToInkAll[msg.sender] = addressToInkAll[msg.sender] + 2;
        
        totalInk = 2;
    }
    
    function participateInAuction(uint8 ink) public nonReentrant payable {
        require(ink <= maximumInk - totalInk);
        require(msg.value >= ink * priceOfInk);
        require(auctionIsLive == true);
        require(block.timestamp < blockTimeCounter);

        for(uint8 i=totalInk; i < totalInk + ink; i++){
            inkToAddress[i] = msg.sender;
        }
        
        totalInk = totalInk + ink;
        
        addressToInkAll[msg.sender] = addressToInkAll[msg.sender] + ink;

        uint256 totalSquigglies = totalSupply();
 
        address(0x63a9dbCe75413036B2B778E670aaBd4493aAF9F3).transfer(msg.value/100*65);
        address payable luckyBastard = address(uint160(getLuckyBastard(totalSquigglies)));
        luckyBastard.transfer(msg.value/10);

    }
    
    function calculateInkValue() public view returns (uint256 priceOfInkCalc) {
        if (auctionIsLive == false) {
            if (priceGoUp == true) {
                priceOfInkCalc = priceOfInk*101/100;
            }
            else if (priceGoDown == true) {
                priceOfInkCalc = priceOfInk*99/100;
            }
            else {
                priceOfInkCalc = priceOfInk;
            }
        }
        else {
        priceOfInkCalc = priceOfInk;    
        }
    }
    
    function createSVG() private nonReentrant {
        
        require(totalSupply() <= tokenLimit, "Claimed. Sorry.");
        
        uint256 tokenId = totalSupply();
        
        int luckyCollectorID = getNumber(totalSupply(),0,totalInk - 1);
        address luckyCollectorAddress = inkToAddress[uint8(luckyCollectorID)];
        uint256 seedSVG = uint256(getNumber(1,1,99999999));
        
        idToSVGSeed[tokenId] = seedSVG;
        idToCreator[tokenId] = msg.sender;
        
        _mint(luckyCollectorAddress, tokenId);
        
    }
    
    function createPromo(string memory promoSVG) public onlyOwner {
        require(totalSupply() <= 4);
        
        uint256 tokenId = totalSupply();
        
        idToPromoSVG[tokenId] = promoSVG;
        idToCreator[tokenId] = msg.sender;
        addressToInkAll[msg.sender] = addressToInkAll[msg.sender] + 100;
        
        _mint(msg.sender, tokenId);
    }
    
    function endAuction() public {
        
        if (totalSupply() <= 19) {
        require(block.timestamp >= blockTimeCounter || totalInk == 100);    
        }
        else {
        require(block.timestamp >= blockTimeCounter);            
        }

        require(_auctioneers.has(msg.sender), "Only official Auctioneers can end an auction.");
        
        createSVG();
        auctionIsLive = false;

        for(uint8 i=0; i < 100; i++){
            inkToAddress[i] = 0x0000000000000000000000000000000000000000;
        }
                
        if (totalInk > 80) {
            priceGoUp = true;
            priceGoDown = false;
        }
        else if (totalInk < 60) {
            priceGoDown = true;
            priceGoUp = false;
        }
        else {
            priceGoUp = false;
            priceGoDown = false;
        }
        
        totalInk = 0;
        
        uint256 contractBalance = uint256(address(this).balance);
        uint256 promoRewards = contractBalance/5*2;
        uint256 endAuctionBounty = contractBalance/5*3;
        
    for (uint8 i = 0; i < totalPromoClaimants; i++) {
        address payable promoTransferAddress = address(uint160(promoClaimantStorage[i]));
        promoTransferAddress.transfer(promoRewards/totalPromoClaimants);
        }
        
        address(msg.sender).transfer(endAuctionBounty);    
    }    
    
    function getLuckyBastard(uint256 seed) public view returns (address luckyBastardWinner) {
        uint8 squigglyID = uint8(getNumber(seed, 0, int256(seed - 1)));
        luckyBastardWinner = (ownerOf(squigglyID));
    }

    
    function updateGalleryLink(string memory newURL) public onlyOwner {
        squigglyGalleryLink = newURL;
    }

    function addPromoClaimant(address newPromoClaimant, uint8 newPromoSlot) public onlyOwner {
        require(totalPromoClaimants <= 16);
        require(newPromoSlot <= 15);

        if (promoClaimantStorage[newPromoSlot] == address(0x0000000000000000000000000000000000000000)) {
        totalPromoClaimants = totalPromoClaimants + 1;    
        }
        
        promoClaimantStorage[newPromoSlot] = newPromoClaimant;
    }
    
    function addAuctioneer(address newAuctioneer) public onlyOwner {
        _auctioneers.add(newAuctioneer);
    }
    
    function removeAuctioneer(address newAuctioneer) public onlyOwner {
        _auctioneers.remove(newAuctioneer);
    }

    function integerToString(uint _i) internal pure returns (string memory) {
      if (_i == 0) {
         return "0";
      }
      uint j = _i;
      uint len;
      
      while (j != 0) {
         len++;
         j /= 10;
      }
      bytes memory bstr = new bytes(len);
      uint k = len - 1;
      
      while (_i != 0) {
         bstr[k--] = byte(uint8(48 + _i % 10));
         _i /= 10;
      }
      return string(bstr);
   }

    function tokenURI(uint256 id) external view returns (string memory) {
        require(_exists(id), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(referenceURI, integerToString(uint256(id))));
    }
    
    function getAddressToInkAll(address userAddress) public view returns (uint256 allTimeInk) {
        return addressToInkAll[userAddress];
    }
    
    function getAddressToInk(address userAddress) public view returns (uint8 currentInkCount) {
        for(uint8 i=0; i < 100; i++){
            if(inkToAddress[i] == userAddress) {
                currentInkCount = currentInkCount + 1;
            }  
        }
    }
    
    function getInktoAddress(uint8 ink) public view returns (address userAddress) {
        return inkToAddress[ink];
    }
    
    function getIdToSVG(uint8 tokenId) public view returns (string memory squigglySVG) {
        if(tokenId <= 4){
        squigglySVG = idToPromoSVG[tokenId];
        }
        else {
        squigglySVG = renderFromSeed(idToSVGSeed[tokenId]);
        }
    }
    
    function getIdToCurveType(uint8 tokenId) public view returns (uint256 curveType) {
        bytes32[] memory hashchain = Random.init(idToSVGSeed[tokenId]);
        
        if(tokenId == 0){
        curveType = 4;
        }
        else if(tokenId == 1) {
        curveType = 1;    
        }
        else if(tokenId == 2) {
        curveType = 5;    
        }
        else if(tokenId == 3) {
        curveType = 2;    
        }
        else if(tokenId == 4) {
        curveType = 3;    
        }
        else {
        curveType = Random.uniform_uint(hashchain,1,5);
        }
    }
    
    function getIdToCreator(uint8 tokenId) public view returns (address userAddress) {
        return idToCreator[tokenId];
    }
    
    function updateURI(string memory newURI) public onlyOwner {
        referenceURI = newURI;
    }
    function readStats() public view returns (string memory auctionStatus, uint8 inkRemaining, uint256 artRemaining, int256 secondsRemaining) {

        artRemaining = 100 - totalSupply();
        inkRemaining = maximumInk - totalInk;
        secondsRemaining = int256(blockTimeCounter - block.timestamp);
        
        if (secondsRemaining > 0 && inkRemaining > 0) {
            secondsRemaining = secondsRemaining;
        }
        else if (secondsRemaining > 0 && totalSupply() > 19) {
            secondsRemaining = secondsRemaining;
        }
        else {
            secondsRemaining = 0;
        }

        if (artRemaining == 0) {
            auctionStatus = string('Art sale is over.');
        }
        else if (auctionIsLive == false) {
            auctionStatus = string(abi.encodePacked('Auction is not active. Next token is: ', integerToString(100 - artRemaining)));
        }
        else if (secondsRemaining <= 0) {
            auctionStatus = string('Waiting on Auctioneer to call End Auction.');
        }
        else {
            auctionStatus = string(abi.encodePacked('Auction for token #', integerToString(100 - artRemaining) ,' is live.'));
        }
        
    }    
    
}
