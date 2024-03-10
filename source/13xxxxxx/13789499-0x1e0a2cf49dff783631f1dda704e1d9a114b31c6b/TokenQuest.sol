// SPDX-License-Identifier: MIT

// www.tokenquest.xyz
// info@tokenquest.xyz
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////%@@@@@@@@@@@@@@@#///////////////////////////////
////////////////////////////////%@@@@@@@@@@@@@@@#///////////////////////////////
////////////////////////%@@@@@@@/...............#@@@@@@@#///////////////////////
////////////////////////%@@@@@@@/...............#@@@@@@@#///////////////////////
////////////////////%@@@(...............................#@@@#///////////////////
////////////////%@@@(........   ,///////////////,....   ....#@@@#///////////////
////////////////%@@@(........   ,///////////////,....   ....#@@@#///////////////
////////////#@@@(.......    ,///**,*,*,*,*,*,*,**///,........   %@@@#///////////
////////////#@@@(....   ,********,,,,,,,,,,,,....,,,****........%@@@#///////////
////////////#@@@(...    ,///**,*,*,*,*,*,*,*.   ....*///,   ....%@@@#///////////
////////%@@@#.......*///*,,,,,,,,,,,,,,,.   .........   ,,,,,.......%@@@#///////
////////%@@@#.......*///**,*,*,*,*,*,*,*.   .........   ,*,*,.......%@@@#///////
////////%@@@#.......*///*,,,,,,,,,,,.   .........       ,,,,,.......%@@@#///////
////////%@@@#.......*///**,*,*,*.   .........           ,*,*,.......%@@@#///////
////////%@@@#.......*///*,,,,,,,.   .........           ,,,,,.......%@@@#///////
////////////#@@@(.......*///,   .........           ,*,*.   ....%@@@#///////////
////////////#@@@(...........,,,,,.......        .,,,............%@@@#///////////
////////////#@@@(........   .*,*,....           ,*,*.   ........%@@@#///////////
////////////////%@@@/   ........,,,,,,,,,,,,,,,,.   ........#@@@#///////////////
////////////////%@@@/   ........,*,*,*,*,*,*,*,*.   ........#@@@#///////////////
////////////////////%@@@(....   ........................#@@@#///////////////////
////////////////////////%@@@@@@@/...............#@@@@@@@#///////////////////////
////////////////////////%@@@@@@@/...............#@@@@@@@#///////////////////////
////////////////////////////////%@@@@@@@@@@@@@@@#///////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

pragma solidity 0.8.10;

import "ContextMixin.sol";
import "IERC721.sol";
import "IERC721Receiver.sol";
import "IERC721Metadata.sol";
import "Address.sol";
import "Strings.sol";
import "ERC165.sol";

interface IEIP2309 {
    event ConsecutiveTransfer(
        uint256 indexed fromTokenId,
        uint256 toTokenId,
        address indexed fromAddress,
        address indexed toAddress
    );
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract TokenQuest is
    ContextMixin,
    ERC165,
    IERC721,
    IERC721Metadata,
    IEIP2309
{
    using Address for address;
    using Strings for uint256;

    address private _proxyRegistryAddress;

    uint256 constant TOTAL_SUPPLY = 4096;

    address private _contractManager;

    string private _name;

    string private _symbol;

    string private _storageLocation;

    mapping(uint256 => address) private _owners;

    mapping(address => uint256) private _balances;

    mapping(uint256 => address) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(address openseaProxyRegistry) public {
        _name = "TokenQuest";
        _symbol = "TOKQ";
        _storageLocation = "https://storage.googleapis.com/tokenquest.appspot.com/";
        _contractManager = msg.sender;
        _proxyRegistryAddress = openseaProxyRegistry;
    }

    function mintAll() public {
        require(msg.sender == _contractManager);
        _balances[_contractManager] = TOTAL_SUPPLY;
        emit ConsecutiveTransfer(
            0,
            TOTAL_SUPPLY - 1,
            address(0),
            _contractManager
        );
    }

    function contractManager() public view virtual returns (address) {
        return _contractManager;
    }

    function isValidToken(uint256 tokenId) public view returns (bool) {
        return tokenId >= 0 && tokenId < TOTAL_SUPPLY;
    }

    modifier onlyValidTokens(uint256 tokenId) {
        require(isValidToken(tokenId), "Invalid token");
        _;
    }

    function setBaseURI(string memory baseURI) public {
        require(msg.sender == _contractManager);
        _storageLocation = baseURI;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return _storageLocation;
    }

    function contractURI() public view returns (string memory) {
        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, "tq.json"));
    }

    function totalSupply() public view returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function numClaimed() public view returns (uint256) {
        return TOTAL_SUPPLY - _balances[_contractManager];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        override
        returns (address owner)
    {
        require(isValidToken(tokenId), "query for invalid token");
        owner = _owners[tokenId];
        if (owner == address(0)) {
            return _contractManager;
        }
        return owner;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return isValidToken(tokenId); // All valid tokens exist.
    }

    function exists(uint256 _id) external view returns (bool) {
        return _exists(_id);
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
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(to != _contractManager, "Can't transfer to contract manager");
    }

    // Modified to allow OpenSea to use their proxy.
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }
        return _operatorApprovals[owner][operator];
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner,
     * but by OpenSea.
     */
    function _msgSender() internal view returns (address sender) {
        return ContextMixin.msgSender();
    }

    // Below is largely untouched from the OpenZeppelin implementation, except:
    // - ERC721.ownerOf() => ownerOf(),
    // - tokenURI change to add nft/{id}.json,
    // - _burn has been deleted,
    // - _mint has been deleted, and
    // - _safeMint has been deleted.

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
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
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        abi.encodePacked(
                            "nft/",
                            abi.encodePacked(tokenId.toString(), ".json")
                        )
                    )
                )
                : "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
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
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

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
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
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
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
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
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
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
        emit Approval(ownerOf(tokenId), to, tokenId);
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
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
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
}

