// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./WhiteList.sol";

contract MetacaskNFT is ERC721, ERC721URIStorage, Pausable, AccessControl, WhiteList {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ROYALTY_CHECK_ROLE = keccak256("ROYALTY_CHECK_ROLE");

    // Mapping from token ID to originator's commission address
    mapping(uint256 => address) private _commissionAddresses;
    mapping(uint256 => uint256) private _commissionRates;

    // base labs uri
    string private _baseLabsURI;

    /**
     * Emitted when `owner` adds `commissionAddress` to `tokenId` token.
     */
    event SetCommission(address indexed owner, address indexed commissionAddress, uint256 indexed tokenId);

    constructor() ERC721("MetacaskNFT", "MCK") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(ROYALTY_CHECK_ROLE, msg.sender);
        _baseLabsURI = "https://ipfs.io/ipfs/";
    }

    /// @dev Add an account to the minter role. Restricted to admin.
    function addMinter(address account) public
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        grantRole(MINTER_ROLE, account);
    }

    /// @dev Remove an account from the minter role. Restricted to admin.
    function removeMinter(address account) public
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        revokeRole(MINTER_ROLE, account);
    }

    /// @dev Add an account to the royalty check role. Restricted to admin.
    function addRoyaltyChecker(address account) public
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        grantRole(ROYALTY_CHECK_ROLE, account);
    }

    /// @dev Remove an account from the royalty check role. Restricted to admin.
    function removeRoyaltyChecker(address account) public
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        revokeRole(ROYALTY_CHECK_ROLE, account);
    }

    function pause() public {
        require(hasRole(PAUSER_ROLE, msg.sender));
        _pause();
    }

    function unpause() public {
        require(hasRole(PAUSER_ROLE, msg.sender));
        _unpause();
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseLabsURI;
    }

    function setBaseLabsURI(string memory uri) public
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _baseLabsURI = uri;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        onlyWhiteListed(to)
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId)
        internal
        onlyWhiteListed(to)
        override
    {
        super._transfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev get address for originator commission
     */
    function getCommissionAddress(uint256 tokenId) public view virtual returns (address) {
        require(hasRole(ROYALTY_CHECK_ROLE, msg.sender));
        require(_exists(tokenId), "MetacaskNFT: commission address query for nonexistent token");

        return _commissionAddresses[tokenId];
    }

    /**
     * @dev get address for originator commission
     */
    function getCommissionRate(uint256 tokenId) public view virtual returns (uint256) {
        require(hasRole(ROYALTY_CHECK_ROLE, msg.sender));
        require(_exists(tokenId), "MetacaskNFT: commission address query for nonexistent token");

        return _commissionRates[tokenId];
    }

    /**
     * @dev set address for originator commission
     *
     * Emits an {SetCommission} event.
     */
    function _setCommission(uint256 tokenId, address commissionAddress, uint256 commissionRate) internal virtual {
        _commissionAddresses[tokenId] = commissionAddress;
        _commissionRates[tokenId] = commissionRate;
        emit SetCommission(ERC721.ownerOf(tokenId), commissionAddress, tokenId);
    }

    /**
     * @dev mint Item for metacask NFT
     */
    function mintItem(address to, string memory myTokenURI, address commissionAddress, uint256 commissionRate)
        public
        onlyWhiteListed(to)
        returns (uint256)
    {
        require(hasRole(MINTER_ROLE, msg.sender));
        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _safeMint(to, id);
        _setTokenURI(id, myTokenURI);
        _setCommission(id, commissionAddress, commissionRate);

        return id;
    }
}

