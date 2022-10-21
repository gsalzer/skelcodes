// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./access/AdminControlUpgradeable.sol";
import "./core/ERC721ProjectCoreUpgradeable.sol";

/**
 * @dev ERC721Project implementation
 */
abstract contract ERC721ProjectUpgradeable is
    Initializable,
    AdminControlUpgradeable,
    ERC721Upgradeable,
    ERC721ProjectCoreUpgradeable,
    UUPSUpgradeable
{
    function _initialize(string memory _name, string memory _symbol) internal initializer {
        __AdminControl_init();
        __ERC721_init(_name, _symbol);
        __ERC721ProjectCore_init();
        __UUPSUpgradeable_init();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AdminControlUpgradeable, ERC721Upgradeable, ERC721ProjectCoreUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        _approveTransfer(from, to, tokenId);
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IProjectCore-registerManager}.
     */
    function registerManager(address manager, string calldata baseURI)
        external
        override
        adminRequired
        nonBlacklistRequired(manager)
    {
        _registerManager(manager, baseURI, false);
    }

    /**
     * @dev See {IProjectCore-registerManager}.
     */
    function registerManager(
        address manager,
        string calldata baseURI,
        bool baseURIIdentical
    ) external override adminRequired nonBlacklistRequired(manager) {
        _registerManager(manager, baseURI, baseURIIdentical);
    }

    /**
     * @dev See {IProjectCore-unregisterManager}.
     */
    function unregisterManager(address manager) external override adminRequired {
        _unregisterManager(manager);
    }

    /**
     * @dev See {IProjectCore-blacklistManager}.
     */
    function blacklistManager(address manager) external override adminRequired {
        _blacklistManager(manager);
    }

    /**
     * @dev See {IProjectCore-managerSetBaseTokenURI}.
     */
    function managerSetBaseTokenURI(string calldata uri) external override managerRequired {
        _managerSetBaseTokenURI(uri, false);
    }

    /**
     * @dev See {IProjectCore-managerSetBaseTokenURI}.
     */
    function managerSetBaseTokenURI(string calldata uri, bool identical) external override managerRequired {
        _managerSetBaseTokenURI(uri, identical);
    }

    /**
     * @dev See {IProjectCore-managerSetTokenURIPrefix}.
     */
    function managerSetTokenURIPrefix(string calldata prefix) external override managerRequired {
        _managerSetTokenURIPrefix(prefix);
    }

    /**
     * @dev See {IProjectCore-managerSetTokenURI}.
     */
    function managerSetTokenURI(uint256 tokenId, string calldata uri) external override managerRequired {
        _managerSetTokenURI(tokenId, uri);
    }

    /**
     * @dev See {IProjectCore-managerSetTokenURI}.
     */
    function managerSetTokenURI(uint256[] calldata tokenIds, string[] calldata uris) external override managerRequired {
        require(tokenIds.length == uris.length, "Invalid input");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _managerSetTokenURI(tokenIds[i], uris[i]);
        }
    }

    /**
     * @dev See {IProjectCore-setBaseTokenURI}.
     */
    function setBaseTokenURI(string calldata uri) external override adminRequired {
        _setBaseTokenURI(uri);
    }

    /**
     * @dev See {IProjectCore-setTokenURIPrefix}.
     */
    function setTokenURIPrefix(string calldata prefix) external override adminRequired {
        _setTokenURIPrefix(prefix);
    }

    /**
     * @dev See {IProjectCore-setTokenURI}.
     */
    function setTokenURI(uint256 tokenId, string calldata uri) external override adminRequired {
        _setTokenURI(tokenId, uri);
    }

    /**
     * @dev See {IProjectCore-setTokenURI}.
     */
    function setTokenURI(uint256[] calldata tokenIds, string[] calldata uris) external override adminRequired {
        require(tokenIds.length == uris.length, "Invalid input");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _setTokenURI(tokenIds[i], uris[i]);
        }
    }

    /**
     * @dev See {IProjectCore-setMintPermissions}.
     */
    function setMintPermissions(address manager, address permissions) external override adminRequired {
        _setMintPermissions(manager, permissions);
    }

    /**
     * @dev See {IERC721ProjectCore-adminMint}.
     */
    function adminMint(address to, string calldata uri)
        external
        virtual
        override
        nonReentrant
        adminRequired
        returns (uint256)
    {
        return _adminMint(to, uri);
    }

    /**
     * @dev See {IERC721ProjectCore-adminMintBatch}.
     */
    function adminMintBatch(address to, uint16 count)
        external
        virtual
        override
        nonReentrant
        adminRequired
        returns (uint256[] memory tokenIds)
    {
        tokenIds = new uint256[](count);
        for (uint16 i = 0; i < count; i++) {
            tokenIds[i] = _adminMint(to, "");
        }
        return tokenIds;
    }

    /**
     * @dev See {IERC721ProjectCore-adminMintBatch}.
     */
    function adminMintBatch(address to, string[] calldata uris)
        external
        virtual
        override
        nonReentrant
        adminRequired
        returns (uint256[] memory tokenIds)
    {
        tokenIds = new uint256[](uris.length);
        for (uint256 i = 0; i < uris.length; i++) {
            tokenIds[i] = _adminMint(to, uris[i]);
        }
        return tokenIds;
    }

    /**
     * @dev Mint token with no manager
     */
    function _adminMint(address to, string memory uri) internal virtual returns (uint256 tokenId) {
        _tokenCount++;
        tokenId = _tokenCount;

        // Track the manager that minted the token
        _tokensManager[tokenId] = address(this);

        _safeMint(to, tokenId);

        if (bytes(uri).length > 0) {
            _tokenURIs[tokenId] = uri;
        }

        // Call post mint
        _postMintBase(to, tokenId);
        return tokenId;
    }

    /**
     * @dev See {IERC721ProjectCore-managerMint}.
     */
    function managerMint(address to, string calldata uri)
        external
        virtual
        override
        nonReentrant
        managerRequired
        returns (uint256)
    {
        return _managerMint(to, uri);
    }

    /**
     * @dev See {IERC721ProjectCore-managerMintBatch}.
     */
    function managerMintBatch(address to, uint16 count)
        external
        virtual
        override
        nonReentrant
        managerRequired
        returns (uint256[] memory tokenIds)
    {
        tokenIds = new uint256[](count);
        for (uint16 i = 0; i < count; i++) {
            tokenIds[i] = _managerMint(to, "");
        }
        return tokenIds;
    }

    /**
     * @dev See {IERC721ProjectCore-managerMintBatch}.
     */
    function managerMintBatch(address to, string[] calldata uris)
        external
        virtual
        override
        nonReentrant
        managerRequired
        returns (uint256[] memory tokenIds)
    {
        tokenIds = new uint256[](uris.length);
        for (uint256 i = 0; i < uris.length; i++) {
            tokenIds[i] = _managerMint(to, uris[i]);
        }
    }

    /**
     * @dev Mint token via manager
     */
    function _managerMint(address to, string memory uri) internal virtual returns (uint256 tokenId) {
        _tokenCount++;
        tokenId = _tokenCount;

        _checkMintPermissions(to, tokenId);

        // Track the manager that minted the token
        _tokensManager[tokenId] = msg.sender;

        _safeMint(to, tokenId);

        if (bytes(uri).length > 0) {
            _tokenURIs[tokenId] = uri;
        }

        // Call post mint
        _postMintManager(to, tokenId);
        return tokenId;
    }

    /**
     * @dev See {IERC721ProjectCore-tokenManager}.
     */
    function tokenManager(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "Nonexistent token");
        return _tokenManager(tokenId);
    }

    /**
     * @dev See {IERC721ProjectCore-burn}.
     */
    function burn(uint256 tokenId) public virtual override nonReentrant {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner nor approved");
        address owner = ownerOf(tokenId);
        _burn(tokenId);
        _postBurn(owner, tokenId);
    }

    /**
     * @dev See {IProjectCore-setRoyalties}.
     */
    function setRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints)
        external
        override
        adminRequired
    {
        _setRoyaltiesManager(address(this), receivers, basisPoints);
    }

    /**
     * @dev See {IProjectCore-setRoyalties}.
     */
    function setRoyalties(
        uint256 tokenId,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) external override adminRequired {
        require(_exists(tokenId), "Nonexistent token");
        _setRoyalties(tokenId, receivers, basisPoints);
    }

    /**
     * @dev See {IProjectCore-setRoyaltiesManager}.
     */
    function setRoyaltiesManager(
        address manager,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) external override adminRequired {
        _setRoyaltiesManager(manager, receivers, basisPoints);
    }

    /**
     * @dev {See IProjectCore-getRoyalties}.
     */
    function getRoyalties(uint256 tokenId)
        external
        view
        virtual
        override
        returns (address payable[] memory, uint256[] memory)
    {
        require(_exists(tokenId), "Nonexistent token");
        return _getRoyalties(tokenId);
    }

    /**
     * @dev {See IProjectCore-getFees}.
     */
    function getFees(uint256 tokenId)
        external
        view
        virtual
        override
        returns (address payable[] memory, uint256[] memory)
    {
        require(_exists(tokenId), "Nonexistent token");
        return _getRoyalties(tokenId);
    }

    /**
     * @dev {See IProjectCore-getFeeRecipients}.
     */
    function getFeeRecipients(uint256 tokenId) external view virtual override returns (address payable[] memory) {
        require(_exists(tokenId), "Nonexistent token");
        return _getRoyaltyReceivers(tokenId);
    }

    /**
     * @dev {See IProjectCore-getFeeBps}.
     */
    function getFeeBps(uint256 tokenId) external view virtual override returns (uint256[] memory) {
        require(_exists(tokenId), "Nonexistent token");
        return _getRoyaltyBPS(tokenId);
    }

    /**
     * @dev {See IProjectCore-royaltyInfo}.
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 value,
        bytes calldata
    )
        external
        view
        virtual
        override
        returns (
            address,
            uint256,
            bytes memory
        )
    {
        require(_exists(tokenId), "Nonexistent token");
        return _getRoyaltyInfo(tokenId, value);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");
        return _tokenURI(tokenId);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    uint256[50] private __gap;
}

