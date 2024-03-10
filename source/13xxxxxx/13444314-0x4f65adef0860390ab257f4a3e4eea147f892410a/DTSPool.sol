// SPDX-License-Identifier: MIT

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

// File: contracts/Staking.sol


pragma solidity ^0.8.9;


contract DTSPool is Ownable {
    event DepositNFT(address indexed from, address indexed tokenContract, uint256 indexed tokenID);
    event WithdrawNFT(address indexed from, address indexed tokenContract, uint256 indexed tokenID);
    
    // DAO Turtles Staking Pool
    address constant public DTS_VAULT = 0xA3ACd9eD1334b6c33E3b1D88394e1E2b771A5795;
    
    bool public canDepositNFT = true;
    bool public canWithdrawNFT = true;
    
    // map each NFT contract to map of tokenID: stakerAddress 
    mapping (address => mapping (uint256 => address)) public NFTStakers;
    
    function flipDepositNFT() external onlyOwner {
        canDepositNFT = !canDepositNFT;
    }
    
    function flipWithdrawNFT() external onlyOwner {
        canWithdrawNFT = !canWithdrawNFT;
    }
    
    function depositNFT(address tokenContract, uint256 tokenID) external {
        require(canDepositNFT, "Closed for deposits");
        IERC721Enumerable ITokenContract = IERC721Enumerable(tokenContract);
        require(ITokenContract.ownerOf(tokenID) == msg.sender, "Token not owned");
        ITokenContract.safeTransferFrom(msg.sender, DTS_VAULT, tokenID);
        NFTStakers[tokenContract][tokenID] = msg.sender;
        emit DepositNFT(msg.sender, tokenContract, tokenID);
    }
    
    function depositMultipleNFTs(address tokenContract, uint256 amount, uint256[] calldata tokenIDList) external {
        require(canDepositNFT, "Closed for deposits");
        require(amount <= 10, "Too many NFTs");
        IERC721Enumerable ITokenContract = IERC721Enumerable(tokenContract);
        uint256 tokenID;
        for (uint256 i=0; i<amount; i++) {
            tokenID = tokenIDList[i];
            require(ITokenContract.ownerOf(tokenID) == msg.sender, "Token not owned");
            ITokenContract.safeTransferFrom(msg.sender, DTS_VAULT, tokenID);
            NFTStakers[tokenContract][tokenID] = msg.sender;
            emit DepositNFT(msg.sender, tokenContract, tokenID);
        }
    }

    function withdrawNFT(address tokenContract, uint256 tokenID) external {
        require(canWithdrawNFT, "Closed for withdrawals");
        // Token staker must be the caller
        require(NFTStakers[tokenContract][tokenID] == msg.sender, "Token not owned");
        IERC721Enumerable(tokenContract).safeTransferFrom(DTS_VAULT, msg.sender, tokenID);
        delete NFTStakers[tokenContract][tokenID];
        emit WithdrawNFT(msg.sender, tokenContract, tokenID);
    }
    
    function withdrawMultipleNFT(address tokenContract, uint256 amount, uint256[] calldata tokenIDList) external {
        require(canWithdrawNFT, "Closed for withdrawals");
        require(amount <= 10, "Too many NFTs");
        IERC721Enumerable ITokenContract = IERC721Enumerable(tokenContract);
        uint256 tokenID;
        for (uint256 i=0; i<amount; i++) {
            tokenID = tokenIDList[i];
            require(NFTStakers[tokenContract][tokenID] == msg.sender, "Token not owned");
            ITokenContract.safeTransferFrom(DTS_VAULT, msg.sender, tokenID);
            delete NFTStakers[tokenContract][tokenID];
            emit WithdrawNFT(msg.sender, tokenContract, tokenID);
        }
    }

    function getNumberOfStakedTokens(address staker, address tokenContract) public view returns (uint256) {
        uint256 count;
        uint256 maxTokens = IERC721Enumerable(tokenContract).totalSupply();
        for (uint256 i=0; i < maxTokens; i++) {
            if (NFTStakers[tokenContract][i] == staker) {
                count++;
            }
        }
        return count;
        
    }

    function getStakedTokens(address staker, address tokenContract) external view returns (uint256[] memory) {
        uint256 count = getNumberOfStakedTokens(staker, tokenContract);
        uint256 maxTokens = IERC721Enumerable(tokenContract).totalSupply();
        uint256[] memory tokens = new uint256[](count);
        uint256 n;
        for (uint256 i=0; i < maxTokens; i++) {
            if (NFTStakers[tokenContract][i] == staker) {
                tokens[n] = i;
                n++;
            }
        }
        return tokens;
    }

    function getUnstakedTokens(address staker, address tokenContract) external view returns (uint256[] memory) {
        IERC721Enumerable ITokenContract = IERC721Enumerable(tokenContract);
        uint256 count = ITokenContract.balanceOf(staker);
        uint256 maxTokens = ITokenContract.totalSupply();
        uint256[] memory tokens = new uint256[](count);
        uint256 n;
        for (uint256 i=0; i < maxTokens; i++) {
            if (ITokenContract.ownerOf(i) == staker) {
                tokens[n] = i;
                n++;
            }
        }
        return tokens;
    }
    
    function isStakedByAddress(address staker, address tokenContract, uint256 tokenID) external view returns (bool){
        if (NFTStakers[tokenContract][tokenID] == staker) {
            return true;
        } else {
            return false;
        }
    }
}
