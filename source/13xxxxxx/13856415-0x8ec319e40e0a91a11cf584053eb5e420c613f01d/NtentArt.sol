// SPDX-License-Identifier: MIT

// File contracts/libs/IERC165.sol

// File: openzeppelin-solidity/contracts/introspection/IERC165.sol
pragma solidity ^0.8.9;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * [EIP](https://eips.ethereum.org/EIPS/eip-165).
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others (`ERC165Checker`).
 *
 * For an implementation, see `ERC165`.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File contracts/libs/ERC165.sol

// File: openzeppelin-solidity/contracts/introspection/ERC165.sol

pragma solidity ^0.8.9;


/**
 * @dev Implementation of the `IERC165` interface.
 *
 * Contracts may inherit from this and call `_registerInterface` to declare
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

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See `IERC165.supportsInterface`.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) override external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See `IERC165.supportsInterface`.
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


// File contracts/libs/IERC721.sol

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721.sol

pragma solidity ^0.8.9;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
abstract contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public virtual view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public virtual view returns (address owner);

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
     * NFT by either `approve` or `setApproveForAll`.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either `approve` or `setApproveForAll`.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual;
    function approve(address to, uint256 tokenId) public virtual;
    function getApproved(uint256 tokenId) public virtual view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public virtual;
    function isApprovedForAll(address owner, address operator) public virtual view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual;
}


// File contracts/libs/Address.sol

// File: openzeppelin-solidity/contracts/utils/Address.sol

pragma solidity ^0.8.9;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}


// File contracts/libs/Counters.sol

// File: openzeppelin-solidity/contracts/drafts/Counters.sol

pragma solidity ^0.8.9;



/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the SafeMath
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
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
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value - 1;
    }
}


// File contracts/libs/IERC721Receiver.sol

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol

pragma solidity ^0.8.9;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
abstract contract IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public virtual returns (bytes4);
}


// File contracts/libs/ERC721.sol

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721.sol

pragma solidity ^0.8.9;



/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is ERC165, IERC721 {
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
    
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }


    function balanceOf(address owner) public override view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }

    function ownerOf(uint256 tokenId) public override view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

    function approve(address to, uint256 tokenId) public override virtual {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public override view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address to, bool approved) public override {
        require(to != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    function isApprovedForAll(address owner, address operator) public override view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(address owner, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
    internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

// File contracts/libs/IERC721Enumerable.sol
// File: openzeppelin-solidity/contracts/token/ERC721/IERC721Enumerable.sol

pragma solidity ^0.8.9;

abstract contract IERC721Enumerable is IERC721 {
    function totalSupply() public virtual view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public virtual view returns (uint256);
}

// File contracts/libs/ERC721Enumerable.sol
// File: openzeppelin-solidity/contracts/token/ERC721/ERC721Enumerable.sol

pragma solidity ^0.8.9;

contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;


    constructor () {
        // register the supported interface to conform to ERC721Enumerable via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public override view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }


    function totalSupply() public override view returns (uint256) {
        return _allTokens.length;
    }


    function tokenByIndex(uint256 index) public override view returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    function _transferFrom(address from, address to, uint256 tokenId) override internal {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }

    function _mint(address to, uint256 tokenId) override internal {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }

    function _burn(address owner, uint256 tokenId) override internal {
        super._burn(owner, tokenId);

        _removeTokenFromOwnerEnumeration(owner, tokenId);
        // Since tokenId will be deleted, we can clear its slot in _ownedTokensIndex to trigger a gas refund
        _ownedTokensIndex[tokenId] = 0;

        _removeTokenFromAllTokensEnumeration(tokenId);
    }

    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }


    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }
 
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _ownedTokens[from].length - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        _ownedTokens[from].pop();

        // Note that _ownedTokensIndex[tokenId] hasn't been cleared: it still points to the old slot (now occupied by
        // lastTokenId, or just over the end of the array if the token was the last one).
    }


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
        _allTokens.pop();
        _allTokensIndex[tokenId] = 0;
    }
}


// File contracts/libs/CustomERC721Metadata.sol

// File: contracts/CustomERC721Metadata.sol

pragma solidity ^0.8.9;

/**
 * ERC721 base contract without the concept of tokenUri as this is managed by the parent
 */
contract CustomERC721Metadata is ERC721Enumerable {

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /**
     * @dev Constructor function
     */
    constructor (string memory nm, string memory sym) {
        _name = nm;
        _symbol = sym;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    /**
     * @dev Gets the token name
     * @return string representing the token name
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

}

pragma solidity ^0.8.9;

interface NtentTokenUri {
   function tokenUri(uint256 _tokenId) external view returns(string memory);
}

contract NtentArt is CustomERC721Metadata {

    event Mint(
        address indexed _to,
        uint256 indexed _tokenId,
        uint256 indexed _projectId
    );

    struct Project {
        string name;
        string artist;
        string description;
        string website;
        string license;
        address purchaseContract;
        address dataContract;
        address tokenUriContract;
        bool acceptsMintPass;
        uint256 mintPassProjectId;
        bool dynamic;
        string projectBaseURI;
        string projectBaseIpfsURI;
        uint256 invocations;
        uint256 maxInvocations;
        string scriptJSON;
        mapping(uint256 => string) scripts;
        uint scriptCount;
        uint256 tokensBurned; 
        string ipfsHash;
        bool useHashString;
        bool useIpfs;
        bool active;
        bool locked;
        bool paused;

    }

    uint256 constant ONE_MILLION = 1_000_000;
    mapping(uint256 => Project) projects;

    //All financial functions are stripped from struct for visibility
    mapping(uint256 => address) public projectIdToArtistAddress;
    mapping(uint256 => uint256) public projectIdToPricePerTokenInWei;

    address public ntentAddress;
    uint256 public ntentPercentage = 10;

    mapping(uint256 => string) public staticIpfsImageLink;
    mapping(uint256 => uint256) public tokenIdToProjectId;
    mapping(uint256 => uint256[]) internal projectIdToTokenIds;
    mapping(uint256 => bytes32) public tokenIdToHash;
    mapping(bytes32 => uint256) public hashToTokenId;

    address public admin;
    mapping(address => bool) public isRainbowlisted;
    mapping(address => bool) public isMintRainbowlisted;

    uint256 public nextProjectId = 1;

    modifier onlyValidTokenId(uint256 _tokenId) {
        require(_exists(_tokenId), "Token ID not exists");
        _;
    }

    modifier onlyUnlocked(uint256 _projectId) {
        require(!projects[_projectId].locked, "Only if unlocked");
        _;
    }

    modifier onlyArtist(uint256 _projectId) {
        require(msg.sender == projectIdToArtistAddress[_projectId], "Only artist");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    modifier onlyRainbowlisted() {
        require(isRainbowlisted[msg.sender], "Only Rainbowlisted");
        _;
    }

    modifier onlyArtistOrRainbowlisted(uint256 _projectId) {
        require(isRainbowlisted[msg.sender] || msg.sender == projectIdToArtistAddress[_projectId], "Only artist or Rainbowlisted");
        _;
    }

    constructor(string memory _tokenName, string memory _tokenSymbol) CustomERC721Metadata(_tokenName, _tokenSymbol) {
        admin = msg.sender;
        isRainbowlisted[msg.sender] = true;
        ntentAddress = msg.sender;
    }

    function concatenate(string memory a,string memory b) public pure returns (string memory){
        return string(abi.encodePacked(a,b));
    } 

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
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
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function mint(address _to, uint256 _projectId, address _by) external returns (uint256 _tokenId) {
        require(isMintRainbowlisted[msg.sender], "Must mint from Rainbowlisted minter");
        require(projects[_projectId].invocations + 1 <= projects[_projectId].maxInvocations, "Exceeds max invocations");
        require(projects[_projectId].active || _by == projectIdToArtistAddress[_projectId], "Proj must exist and be active");
        require(!projects[_projectId].paused || _by == projectIdToArtistAddress[_projectId], "Purchases are paused");

        uint256 tokenId = _mintToken(_to, _projectId);

        return tokenId;
    }

    function _mintToken(address _to, uint256 _projectId) internal returns (uint256 _tokenId) {

        uint256 tokenIdToBe = (_projectId * ONE_MILLION) + projects[_projectId].invocations;

        projects[_projectId].invocations = projects[_projectId].invocations + 1;

        bytes32 hash = keccak256(abi.encodePacked(projects[_projectId].invocations, block.number, blockhash(block.number - 1), msg.sender, _tokenId));
        tokenIdToHash[tokenIdToBe]=hash;
        hashToTokenId[hash] = tokenIdToBe;

        _mint(_to, tokenIdToBe);

        tokenIdToProjectId[tokenIdToBe] = _projectId;
        projectIdToTokenIds[_projectId].push(tokenIdToBe);

        emit Mint(_to, tokenIdToBe, _projectId);

        return tokenIdToBe;
    }
    
    function burn(address ownerAddress, uint256 tokenId) external returns(uint256 _tokenId) {
        require(isMintRainbowlisted[msg.sender], "Must burn from Rainbowlisted minter");
        _burn(ownerAddress, tokenId);
        projects[tokenIdToProjectId[tokenId]].tokensBurned = projects[tokenIdToProjectId[tokenId]].tokensBurned + 1;
        return tokenId;
    }
    
    function updateNtentAddress(address _ntentAddress) public onlyAdmin {
        ntentAddress = _ntentAddress;
    }

    function updateNtentPercentage(uint256 _ntentPercentage) public onlyAdmin {
        require(_ntentPercentage <= 50, "Max of 50%");
        ntentPercentage = _ntentPercentage;
    }

    function addRainbowlisted(address _address) public onlyAdmin {
        isRainbowlisted[_address] = true;
    }

    function removeRainbowlisted(address _address) public onlyAdmin {
        isRainbowlisted[_address] = false;
    }

    function addMintRainbowlisted(address _address) public onlyAdmin {
        isMintRainbowlisted[_address] = true;
    }

    function removeMintRainbowlisted(address _address) public onlyAdmin {
        isMintRainbowlisted[_address] = false;
    }
    
    function getPricePerTokenInWei(uint256 _projectId) public view returns (uint256 price) {
        return projectIdToPricePerTokenInWei[_projectId];
    }

    function toggleProjectIsLocked(uint256 _projectId) public onlyRainbowlisted onlyUnlocked(_projectId) {
        projects[_projectId].locked = true;
    }

    function toggleProjectIsActive(uint256 _projectId) public onlyRainbowlisted {
        projects[_projectId].active = !projects[_projectId].active;
    }

    function updateProjectArtistAddress(uint256 _projectId, address _artistAddress) public onlyArtistOrRainbowlisted(_projectId) {
        projectIdToArtistAddress[_projectId] = _artistAddress;
    }

    function toggleProjectIsPaused(uint256 _projectId) public onlyArtistOrRainbowlisted(_projectId) {
        projects[_projectId].paused = !projects[_projectId].paused;
    }

    function addProject(string memory _projectName, address _artistAddress, uint256 _pricePerTokenInWei, address _purchaseContract, bool _acceptsMintPass, uint256 _mintPassProjectId, bool _dynamic) public onlyRainbowlisted {

        uint256 projectId = nextProjectId;
        projectIdToArtistAddress[projectId] = _artistAddress;
        projects[projectId].name = _projectName;
        projects[projectId].purchaseContract = _purchaseContract;
        projects[projectId].acceptsMintPass = _acceptsMintPass;
        projects[projectId].mintPassProjectId = _mintPassProjectId;
        projectIdToPricePerTokenInWei[projectId] = _pricePerTokenInWei;
        projects[projectId].paused=true;
        projects[projectId].tokensBurned=0;
        projects[projectId].dynamic=_dynamic;
        projects[projectId].maxInvocations = ONE_MILLION;
        if (!_dynamic) {
            projects[projectId].useHashString = false;
        } else {
            projects[projectId].useHashString = true;
        }
        nextProjectId = nextProjectId + 1;
    }

    function updateProjectPricePerTokenInWei(uint256 _projectId, uint256 _pricePerTokenInWei) onlyArtist(_projectId) public {
        projectIdToPricePerTokenInWei[_projectId] = _pricePerTokenInWei;
    }

    function updateProjectName(uint256 _projectId, string memory _projectName) onlyUnlocked(_projectId) onlyArtistOrRainbowlisted(_projectId) public {
        projects[_projectId].name = _projectName;
    }

    function updateProjectArtistName(uint256 _projectId, string memory _projectArtistName) onlyUnlocked(_projectId) onlyArtistOrRainbowlisted(_projectId) public {
        projects[_projectId].artist = _projectArtistName;
    }
    
    function updateProjectPurchaseContractInfo(uint256 _projectId, address _projectPurchaseContract, bool _acceptsMintPass, uint256 _mintPassProjectId) onlyUnlocked(_projectId) onlyRainbowlisted public {
        projects[_projectId].purchaseContract = _projectPurchaseContract;
        projects[_projectId].acceptsMintPass = _acceptsMintPass;
        projects[_projectId].mintPassProjectId = _mintPassProjectId;
    }
    
    function updateProjectDataContractInfo(uint256 _projectId, address _projectDataContract) onlyUnlocked(_projectId) onlyRainbowlisted public {
        projects[_projectId].dataContract = _projectDataContract;
    }
    
    function updateProjectTokenUriContractInfo(uint256 _projectId, address _projectTokenUriContract) onlyUnlocked(_projectId) onlyRainbowlisted public {
        projects[_projectId].tokenUriContract = _projectTokenUriContract;
    }

    function updateProjectDescription(uint256 _projectId, string memory _projectDescription) onlyArtist(_projectId) public {
        projects[_projectId].description = _projectDescription;
    }

    function updateProjectWebsite(uint256 _projectId, string memory _projectWebsite) onlyArtist(_projectId) public {
        projects[_projectId].website = _projectWebsite;
    }

    function updateProjectLicense(uint256 _projectId, string memory _projectLicense) onlyUnlocked(_projectId) onlyArtistOrRainbowlisted(_projectId) public {
        projects[_projectId].license = _projectLicense;
    }

    function updateProjectMaxInvocations(uint256 _projectId, uint256 _maxInvocations) onlyArtist(_projectId) public {
        require((!projects[_projectId].locked || _maxInvocations<projects[_projectId].maxInvocations), "Only if unlocked");
        require(_maxInvocations > projects[_projectId].invocations, "Max invocations exceeds current");
        require(_maxInvocations <= ONE_MILLION, "Cannot exceed 1000000");
        projects[_projectId].maxInvocations = _maxInvocations;
    }

    function toggleProjectUseHashString(uint256 _projectId) onlyUnlocked(_projectId) onlyArtistOrRainbowlisted(_projectId) public {
      require(projects[_projectId].invocations == 0, "Cannot modify after token is minted.");
      projects[_projectId].useHashString = !projects[_projectId].useHashString;
    }

    function addProjectScript(uint256 _projectId, string memory _script) onlyUnlocked(_projectId) onlyArtistOrRainbowlisted(_projectId) public {
        projects[_projectId].scripts[projects[_projectId].scriptCount] = _script;
        projects[_projectId].scriptCount = projects[_projectId].scriptCount + 1;
    }

    function updateProjectScript(uint256 _projectId, uint256 _scriptId, string memory _script) onlyUnlocked(_projectId) onlyArtistOrRainbowlisted(_projectId) public {
        require(_scriptId < projects[_projectId].scriptCount, "scriptId out of range");
        projects[_projectId].scripts[_scriptId] = _script;
    }

    function removeProjectLastScript(uint256 _projectId) onlyUnlocked(_projectId) onlyArtistOrRainbowlisted(_projectId) public {
        require(projects[_projectId].scriptCount > 0, "there are no scripts to remove");
        delete projects[_projectId].scripts[projects[_projectId].scriptCount - 1];
        projects[_projectId].scriptCount = projects[_projectId].scriptCount + 1;
    }

    function updateProjectScriptJSON(uint256 _projectId, string memory _projectScriptJSON) onlyUnlocked(_projectId) onlyArtistOrRainbowlisted(_projectId) public {
        projects[_projectId].scriptJSON = _projectScriptJSON;
    }

    function updateProjectIpfsHash(uint256 _projectId, string memory _ipfsHash) onlyUnlocked(_projectId) onlyArtistOrRainbowlisted(_projectId) public {
        projects[_projectId].ipfsHash = _ipfsHash;
    }

    function updateProjectBaseURI(uint256 _projectId, string memory _newBaseURI) onlyArtist(_projectId) public {
        projects[_projectId].projectBaseURI = _newBaseURI;
    }

    function updateProjectBaseIpfsURI(uint256 _projectId, string memory _projectBaseIpfsURI) onlyArtist(_projectId) public {
        projects[_projectId].projectBaseIpfsURI = _projectBaseIpfsURI;
    }

    function toggleProjectUseIpfsForStatic(uint256 _projectId) onlyArtistOrRainbowlisted(_projectId) public {
        require(!projects[_projectId].dynamic, "can only set static IPFS hash for static projects");
        projects[_projectId].useIpfs = !projects[_projectId].useIpfs;
    }

    function toggleProjectIsDynamic(uint256 _projectId) onlyUnlocked(_projectId) onlyArtistOrRainbowlisted(_projectId) public {
      require(projects[_projectId].invocations == 0, "Can not switch after a token is minted.");
        if (projects[_projectId].dynamic) {
            projects[_projectId].useHashString = false;
        } else {
            projects[_projectId].useHashString = true;
        }
        projects[_projectId].dynamic = !projects[_projectId].dynamic;
    }

    function overrideTokenDynamicImageWithIpfsLink(uint256 _tokenId, string memory _ipfsHash) onlyArtistOrRainbowlisted(tokenIdToProjectId[_tokenId]) public {
        staticIpfsImageLink[_tokenId] = _ipfsHash;
    }

    function clearTokenIpfsImageUri(uint256 _tokenId) onlyArtistOrRainbowlisted(tokenIdToProjectId[_tokenId]) public {
        delete staticIpfsImageLink[tokenIdToProjectId[_tokenId]];
    }

    function projectDetails(uint256 _projectId) view public returns (string memory projectName, string memory artist, string memory description, string memory website, string memory license, bool dynamic) {
        projectName = projects[_projectId].name;
        artist = projects[_projectId].artist;
        description = projects[_projectId].description;
        website = projects[_projectId].website;
        license = projects[_projectId].license;
        dynamic = projects[_projectId].dynamic;
    }

    function projectTokenInfo(uint256 _projectId) view public returns (address artistAddress, uint256 pricePerTokenInWei, uint256 invocations, uint256 maxInvocations, bool active, address purchaseContract,  address dataContract, address tokenUriContract, bool acceptsMintPass, uint256 mintPassProjectId) {
        artistAddress = projectIdToArtistAddress[_projectId];
        pricePerTokenInWei = projectIdToPricePerTokenInWei[_projectId];
        invocations = projects[_projectId].invocations;
        maxInvocations = projects[_projectId].maxInvocations;
        active = projects[_projectId].active;
        purchaseContract = projects[_projectId].purchaseContract;
        dataContract = projects[_projectId].dataContract;
        tokenUriContract = projects[_projectId].tokenUriContract;
        acceptsMintPass = projects[_projectId].acceptsMintPass;
        mintPassProjectId = projects[_projectId].mintPassProjectId;
    }

    function projectScriptInfo(uint256 _projectId) view public returns (string memory scriptJSON, uint256 scriptCount, bool useHashString, string memory ipfsHash, bool locked, bool paused) {
        scriptJSON = projects[_projectId].scriptJSON;
        scriptCount = projects[_projectId].scriptCount;
        useHashString = projects[_projectId].useHashString;
        ipfsHash = projects[_projectId].ipfsHash;
        locked = projects[_projectId].locked;
        paused = projects[_projectId].paused;
    }

    function projectScriptByIndex(uint256 _projectId, uint256 _index) view public returns (string memory){
        return projects[_projectId].scripts[_index];
    }

    function projectURIInfo(uint256 _projectId) view public returns (string memory projectBaseURI, string memory projectBaseIpfsURI, bool useIpfs) {
        projectBaseURI = projects[_projectId].projectBaseURI;
        projectBaseIpfsURI = projects[_projectId].projectBaseIpfsURI;
        useIpfs = projects[_projectId].useIpfs;
    }

    function projectShowAllTokens(uint _projectId) public view returns (uint256[] memory){
        return projectIdToTokenIds[_projectId];
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        return _tokensOfOwner(owner);
    }

    function tokenURI(uint256 _tokenId) external view onlyValidTokenId(_tokenId) returns (string memory) {

        //check if custom tokenUri contract, if so, use that.
        if(projects[tokenIdToProjectId[_tokenId]].tokenUriContract != address(0)){
            NtentTokenUri ntentTokenUri = NtentTokenUri(projects[tokenIdToProjectId[_tokenId]].tokenUriContract);
            return ntentTokenUri.tokenUri(_tokenId);
        }
        
        //check if tokenId has a specified image link
        if (bytes(staticIpfsImageLink[_tokenId]).length > 0) {
            return concatenate(projects[tokenIdToProjectId[_tokenId]].projectBaseIpfsURI, staticIpfsImageLink[_tokenId]);
        }

        //check if the project has a single overall token Uri (mintpass, etc)
        if (!projects[tokenIdToProjectId[_tokenId]].dynamic && projects[tokenIdToProjectId[_tokenId]].useIpfs) {
            return concatenate(projects[tokenIdToProjectId[_tokenId]].projectBaseIpfsURI, projects[tokenIdToProjectId[_tokenId]].ipfsHash);
        }

        return concatenate(projects[tokenIdToProjectId[_tokenId]].projectBaseURI, uint2str(_tokenId));
    }
}
