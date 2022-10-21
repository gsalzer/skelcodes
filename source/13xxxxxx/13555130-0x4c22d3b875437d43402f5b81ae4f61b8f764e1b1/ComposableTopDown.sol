// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./IERC998ERC721BottomUp.sol";
import "./IERC998ERC721TopDown.sol";
import "./IERC998ERC721TopDownEnumerable.sol";
import "./ERC165.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./Address.sol";
import "./Strings.sol";
import "./EnumerableSet.sol";
import "./IERC721Metadata.sol";

contract ComposableTopDown is
    ERC165,
    IERC721,
    IERC998ERC721TopDown,
    IERC998ERC721TopDownEnumerable,
    IERC721Metadata
{
    using Address for address;
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    // return this.rootOwnerOf.selector ^ this.rootOwnerOfChild.selector ^
    //   this.tokenOwnerOf.selector ^ this.ownerOfChild.selector;
    bytes4 constant ERC998_MAGIC_VALUE = 0xcd740db5;
    bytes32 constant ERC998_MAGIC_VALUE_32 =
        0xcd740db500000000000000000000000000000000000000000000000000000000;

    uint256 tokenCount = 0;

    // tokenId => token owner
    mapping(uint256 => address) private tokenIdToTokenOwner;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping(address => EnumerableSet.UintSet) private _holderTokens;

    // tokenId => last state hash indicator
    mapping(uint256 => uint256) private tokenIdToStateHash;

    // root token owner address => (tokenId => approved address)
    mapping(address => mapping(uint256 => address))
        private rootOwnerAndTokenIdToApprovedAddress;

    // token owner address => token count
    mapping(address => uint256) private tokenOwnerToTokenCount;

    // token owner => (operator address => bool)
    mapping(address => mapping(address => bool)) private tokenOwnerToOperators;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function _safeMint(address _to) internal virtual returns (uint256) {
        require(_to != address(0), "CTD: _to zero addr");
        tokenCount++;
        uint256 tokenCount_ = tokenCount;
        tokenIdToTokenOwner[tokenCount_] = _to;
        _holderTokens[_to].add(tokenCount_);
        tokenOwnerToTokenCount[_to]++;
        tokenIdToStateHash[tokenCount] = uint256(
            keccak256(
                abi.encodePacked(uint256(uint160(address(this))), tokenCount)
            )
        );

        require(
            _checkOnERC721Received(address(0), _to, tokenCount_, ""),
            "CTD: transfer to non ERC721Receiver"
        );
        emit Transfer(address(0), _to, tokenCount_);
        return tokenCount_;
    }

    //from zepellin ERC721Receiver.sol
    //old version
    bytes4 constant ERC721_RECEIVED_OLD = 0xf0b9e5ba;
    //new version
    bytes4 constant ERC721_RECEIVED_NEW = 0x150b7a02;

    bytes4 constant ALLOWANCE = bytes4(keccak256("allowance(address,address)"));
    bytes4 constant APPROVE = bytes4(keccak256("approve(address,uint256)"));
    bytes4 constant ROOT_OWNER_OF_CHILD =
        bytes4(keccak256("rootOwnerOfChild(address,uint256)"));

    ////////////////////////////////////////////////////////
    // ERC721 implementation
    ////////////////////////////////////////////////////////
    function rootOwnerOf(uint256 _tokenId)
        public
        view
        override
        returns (bytes32 rootOwner)
    {
        return rootOwnerOfChild(address(0), _tokenId);
    }

    // returns the owner at the top of the tree of composables
    // Use Cases handled:
    // Case 1: Token owner is this contract and token.
    // Case 2: Token owner is other top-down composable
    // Case 3: Token owner is other contract
    // Case 4: Token owner is user
    function rootOwnerOfChild(address _childContract, uint256 _childTokenId)
        public
        view
        override
        returns (bytes32 rootOwner)
    {
        address rootOwnerAddress;
        if (_childContract != address(0)) {
            (rootOwnerAddress, _childTokenId) = _ownerOfChild(
                _childContract,
                _childTokenId
            );
        } else {
            rootOwnerAddress = tokenIdToTokenOwner[_childTokenId];
            require(
                rootOwnerAddress != address(0),
                "CTD: ownerOf _tokenId zero addr"
            );
        }
        // Case 1: Token owner is this contract and token.
        while (rootOwnerAddress == address(this)) {
            (rootOwnerAddress, _childTokenId) = _ownerOfChild(
                rootOwnerAddress,
                _childTokenId
            );
        }
        bytes memory callData = abi.encodeWithSelector(
            ROOT_OWNER_OF_CHILD,
            address(this),
            _childTokenId
        );
        (bool callSuccess, bytes memory data) = rootOwnerAddress.staticcall(
            callData
        );
        if (callSuccess) {
            assembly {
                rootOwner := mload(add(data, 0x20))
            }
        }

        if (
            callSuccess == true &&
            rootOwner &
                0xffffffff00000000000000000000000000000000000000000000000000000000 ==
            ERC998_MAGIC_VALUE_32
        ) {
            // Case 2: Token owner is other top-down composable
            return rootOwner;
        } else {
            // Case 3: Token owner is other contract
            // Or
            // Case 4: Token owner is user
            assembly {
                rootOwner := or(ERC998_MAGIC_VALUE_32, rootOwnerAddress)
            }
        }
    }

    // returns the owner at the top of the tree of composables

    function ownerOf(uint256 _tokenId)
        public
        view
        override
        returns (address tokenOwner)
    {
        tokenOwner = tokenIdToTokenOwner[_tokenId];
        require(tokenOwner != address(0), "CTD: ownerOf _tokenId zero addr");
        return tokenOwner;
    }

    function balanceOf(address _tokenOwner)
        public
        view
        override
        returns (uint256)
    {
        require(
            _tokenOwner != address(0),
            "CTD: balanceOf _tokenOwner zero addr"
        );
        return tokenOwnerToTokenCount[_tokenOwner];
    }

    function approve(address _approved, uint256 _tokenId) external override {
        address rootOwner = address(uint160(uint256(rootOwnerOf(_tokenId))));
        require(
            rootOwner == msg.sender ||
                tokenOwnerToOperators[rootOwner][msg.sender],
            "CTD: approve msg.sender not owner"
        );
        rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId] = _approved;
        emit Approval(rootOwner, _approved, _tokenId);
    }

    function getApproved(uint256 _tokenId)
        public
        view
        override
        returns (address)
    {
        address rootOwner = address(uint160(uint256(rootOwnerOf(_tokenId))));
        return rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved)
        external
        override
    {
        require(_operator != address(0), "CTD: _operator zero addr");
        tokenOwnerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        override
        returns (bool)
    {
        require(_owner != address(0), "CTD: _owner zero addr");
        require(_operator != address(0), "CTD: _operator zero addr");
        return tokenOwnerToOperators[_owner][_operator];
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override {
        _transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override {
        _transferFrom(_from, _to, _tokenId);
        if (_to.isContract()) {
            bytes4 retval = IERC721Receiver(_to).onERC721Received(
                msg.sender,
                _from,
                _tokenId,
                ""
            );
            require(
                retval == ERC721_RECEIVED_OLD || retval == ERC721_RECEIVED_NEW,
                "CTD: safeTransferFrom(3) onERC721Received invalid return value"
            );
        }
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public override {
        _transferFrom(_from, _to, _tokenId);
        if (_to.isContract()) {
            bytes4 retval = IERC721Receiver(_to).onERC721Received(
                msg.sender,
                _from,
                _tokenId,
                _data
            );
            require(
                retval == ERC721_RECEIVED_OLD || retval == ERC721_RECEIVED_NEW,
                "CTD: safeTransferFrom(4) onERC721Received invalid return value"
            );
            rootOwnerOf(_tokenId);
        }
    }

    function _transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) private {
        require(_from != address(0), "CTD: _from zero addr");
        require(tokenIdToTokenOwner[_tokenId] == _from, "CTD: _from not owner");
        require(_to != address(0), "CTD: _to zero address");

        if (msg.sender != _from) {
            bytes memory callData = abi.encodeWithSelector(
                ROOT_OWNER_OF_CHILD,
                address(this),
                _tokenId
            );
            (bool callSuccess, bytes memory data) = _from.staticcall(callData);
            if (callSuccess == true) {
                bytes32 rootOwner;
                assembly {
                    rootOwner := mload(add(data, 0x20))
                }
                require(
                    rootOwner &
                        0xffffffff00000000000000000000000000000000000000000000000000000000 !=
                        ERC998_MAGIC_VALUE_32,
                    "CTD: token is child of other top down composable"
                );
            }

            require(
                tokenOwnerToOperators[_from][msg.sender] ||
                    rootOwnerAndTokenIdToApprovedAddress[_from][_tokenId] ==
                    msg.sender,
                "CTD: msg.sender not approved"
            );
        }

        // clear approval
        if (
            rootOwnerAndTokenIdToApprovedAddress[_from][_tokenId] != address(0)
        ) {
            delete rootOwnerAndTokenIdToApprovedAddress[_from][_tokenId];
            emit Approval(_from, address(0), _tokenId);
        }

        // remove and transfer token
        if (_from != _to) {
            assert(tokenOwnerToTokenCount[_from] > 0);
            tokenOwnerToTokenCount[_from]--;
            tokenIdToTokenOwner[_tokenId] = _to;
            _holderTokens[_from].remove(_tokenId);
            _holderTokens[_to].add(_tokenId);
            tokenOwnerToTokenCount[_to]++;
        }
        emit Transfer(_from, _to, _tokenId);
    }

    ////////////////////////////////////////////////////////
    // NFT Extendsion Metadata implementation
    ////////////////////////////////////////////////////////

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
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenIdToTokenOwner[tokenId] != address(0);
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
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
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
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        returns (uint256)
    {
        return _holderTokens[owner].at(index);
    }

    function getTokenCount() public view returns (uint256) {
        return tokenCount;
    }

    ////////////////////////////////////////////////////////
    // ERC998ERC721 and ERC998ERC721Enumerable implementation
    ////////////////////////////////////////////////////////

    // tokenId => child contract
    mapping(uint256 => EnumerableSet.AddressSet) private childContracts;

    // tokenId => (child address => array of child tokens)
    mapping(uint256 => mapping(address => EnumerableSet.UintSet))
        private childTokens;

    // child address => childId => tokenId
    mapping(address => mapping(uint256 => uint256)) private childTokenOwner;

    function safeTransferChild(
        uint256 _fromTokenId,
        address _to,
        address _childContract,
        uint256 _childTokenId
    ) external override {
        _transferChild(_fromTokenId, _to, _childContract, _childTokenId);
        IERC721(_childContract).safeTransferFrom(
            address(this),
            _to,
            _childTokenId
        );
        emit TransferChild(_fromTokenId, _to, _childContract, _childTokenId);
    }

    function safeTransferChild(
        uint256 _fromTokenId,
        address _to,
        address _childContract,
        uint256 _childTokenId,
        bytes memory _data
    ) external override {
        _transferChild(_fromTokenId, _to, _childContract, _childTokenId);
        IERC721(_childContract).safeTransferFrom(
            address(this),
            _to,
            _childTokenId,
            _data
        );
        emit TransferChild(_fromTokenId, _to, _childContract, _childTokenId);
    }

    function transferChild(
        uint256 _fromTokenId,
        address _to,
        address _childContract,
        uint256 _childTokenId
    ) external override {
        _transferChild(_fromTokenId, _to, _childContract, _childTokenId);
        //this is here to be compatible with cryptokitties and other old contracts that require being owner and approved
        // before transferring.
        //does not work with current standard which does not allow approving self, so we must let it fail in that case.
        bytes memory callData = abi.encodeWithSelector(
            APPROVE,
            this,
            _childTokenId
        );
        _childContract.call(callData);

        IERC721(_childContract).transferFrom(address(this), _to, _childTokenId);
        emit TransferChild(_fromTokenId, _to, _childContract, _childTokenId);
    }

    function transferChildToParent(
        uint256 _fromTokenId,
        address _toContract,
        uint256 _toTokenId,
        address _childContract,
        uint256 _childTokenId,
        bytes memory _data
    ) external override {
        _transferChild(
            _fromTokenId,
            _toContract,
            _childContract,
            _childTokenId
        );
        IERC998ERC721BottomUp(_childContract).transferToParent(
            address(this),
            _toContract,
            _toTokenId,
            _childTokenId,
            _data
        );
        emit TransferChild(
            _fromTokenId,
            _toContract,
            _childContract,
            _childTokenId
        );
    }

    // this contract has to be approved first in _childContract
    function getChild(
        address _from,
        uint256 _tokenId,
        address _childContract,
        uint256 _childTokenId
    ) external override {
        receiveChild(_from, _tokenId, _childContract, _childTokenId);
        require(
            _from == msg.sender ||
                IERC721(_childContract).isApprovedForAll(_from, msg.sender) ||
                IERC721(_childContract).getApproved(_childTokenId) ==
                msg.sender,
            "CTD: msg.sender not approved"
        );
        IERC721(_childContract).transferFrom(
            _from,
            address(this),
            _childTokenId
        );
        // a check for looped ownership chain
        rootOwnerOf(_tokenId);
    }

    function onERC721Received(
        address _from,
        uint256 _childTokenId,
        bytes calldata _data
    ) external returns (bytes4) {
        require(
            _data.length > 0,
            "CTD: onERC721Received(3) _data must contain the uint256 tokenId to transfer the child token to"
        );
        // convert up to 32 bytes of _data to uint256, owner nft tokenId passed as uint in bytes
        uint256 tokenId = _parseTokenId(_data);
        receiveChild(_from, tokenId, msg.sender, _childTokenId);
        require(
            IERC721(msg.sender).ownerOf(_childTokenId) != address(0),
            "CTD: onERC721Received(3) child token not owned"
        );
        // a check for looped ownership chain
        rootOwnerOf(tokenId);
        return ERC721_RECEIVED_OLD;
    }

    function onERC721Received(
        address,
        address _from,
        uint256 _childTokenId,
        bytes calldata _data
    ) external override returns (bytes4) {
        require(
            _data.length > 0,
            "CTD: onERC721Received(4) _data must contain the uint256 tokenId to transfer the child token to"
        );
        // convert up to 32 bytes of _data to uint256, owner nft tokenId passed as uint in bytes
        uint256 tokenId = _parseTokenId(_data);
        receiveChild(_from, tokenId, msg.sender, _childTokenId);
        require(
            IERC721(msg.sender).ownerOf(_childTokenId) != address(0),
            "CTD: onERC721Received(4) child token not owned"
        );
        // a check for looped ownership chain
        rootOwnerOf(tokenId);
        return ERC721_RECEIVED_NEW;
    }

    function childExists(address _childContract, uint256 _childTokenId)
        external
        view
        returns (bool)
    {
        uint256 tokenId = childTokenOwner[_childContract][_childTokenId];
        return tokenId != 0;
    }

    function totalChildContracts(uint256 _tokenId)
        public
        view
        override
        returns (uint256)
    {
        return childContracts[_tokenId].length();
    }

    function childContractByIndex(uint256 _tokenId, uint256 _index)
        public
        view
        override
        returns (address childContract)
    {
        return childContracts[_tokenId].at(_index);
    }

    function totalChildTokens(uint256 _tokenId, address _childContract)
        public
        view
        override
        returns (uint256)
    {
        return childTokens[_tokenId][_childContract].length();
    }

    function childTokenByIndex(
        uint256 _tokenId,
        address _childContract,
        uint256 _index
    ) public view override returns (uint256 childTokenId) {
        return childTokens[_tokenId][_childContract].at(_index);
    }

    function ownerOfChild(address _childContract, uint256 _childTokenId)
        external
        view
        override
        returns (bytes32 parentTokenOwner, uint256 parentTokenId)
    {
        parentTokenId = childTokenOwner[_childContract][_childTokenId];
        require(parentTokenId != 0, "CTD: not found");
        address parentTokenOwnerAddress = tokenIdToTokenOwner[parentTokenId];
        assembly {
            parentTokenOwner := or(
                ERC998_MAGIC_VALUE_32,
                parentTokenOwnerAddress
            )
        }
    }

    function _transferChild(
        uint256 _fromTokenId,
        address _to,
        address _childContract,
        uint256 _childTokenId
    ) private {
        uint256 tokenId = childTokenOwner[_childContract][_childTokenId];
        require(tokenId != 0, "CTD: _childContract _childTokenId not found");
        require(tokenId == _fromTokenId, "CTD: wrong tokenId found");
        require(_to != address(0), "CTD: _to zero addr");
        address rootOwner = address(uint160(uint256(rootOwnerOf(tokenId))));
        require(
            rootOwner == msg.sender ||
                tokenOwnerToOperators[rootOwner][msg.sender] ||
                rootOwnerAndTokenIdToApprovedAddress[rootOwner][tokenId] ==
                msg.sender,
            "CTD: msg.sender not eligible"
        );
        removeChild(tokenId, _childContract, _childTokenId);
    }

    function _ownerOfChild(address _childContract, uint256 _childTokenId)
        private
        view
        returns (address parentTokenOwner, uint256 parentTokenId)
    {
        parentTokenId = childTokenOwner[_childContract][_childTokenId];
        require(parentTokenId != 0, "CTD: not found");
        return (tokenIdToTokenOwner[parentTokenId], parentTokenId);
    }

    function _parseTokenId(bytes memory _data)
        private
        pure
        returns (uint256 tokenId)
    {
        // convert up to 32 bytes of_data to uint256, owner nft tokenId passed as uint in bytes
        assembly {
            tokenId := mload(add(_data, 0x20))
        }
        if (_data.length < 32) {
            tokenId = tokenId >> (256 - _data.length * 8);
        }
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function removeChild(
        uint256 _tokenId,
        address _childContract,
        uint256 _childTokenId
    ) private {
        // remove child token
        uint256 lastTokenIndex = childTokens[_tokenId][_childContract]
            .length() - 1;
        childTokens[_tokenId][_childContract].remove(_childTokenId);
        delete childTokenOwner[_childContract][_childTokenId];

        // remove contract
        if (lastTokenIndex == 0) {
            childContracts[_tokenId].remove(_childContract);
        }
        if (_childContract == address(this)) {
            _updateStateHash(
                _tokenId,
                uint256(uint160(_childContract)),
                tokenIdToStateHash[_childTokenId]
            );
        } else {
            _updateStateHash(
                _tokenId,
                uint256(uint160(_childContract)),
                _childTokenId
            );
        }
    }

    function receiveChild(
        address _from,
        uint256 _tokenId,
        address _childContract,
        uint256 _childTokenId
    ) private {
        require(
            tokenIdToTokenOwner[_tokenId] != address(0),
            "CTD: _tokenId does not exist."
        );
        require(
            childTokenOwner[_childContract][_childTokenId] != _tokenId,
            "CTD: _childTokenId already received"
        );
        uint256 childTokensLength = childTokens[_tokenId][_childContract]
            .length();
        if (childTokensLength == 0) {
            childContracts[_tokenId].add(_childContract);
        }
        childTokens[_tokenId][_childContract].add(_childTokenId);
        childTokenOwner[_childContract][_childTokenId] = _tokenId;
        if (_childContract == address(this)) {
            _updateStateHash(
                _tokenId,
                uint256(uint160(_childContract)),
                tokenIdToStateHash[_childTokenId]
            );
        } else {
            _updateStateHash(
                _tokenId,
                uint256(uint160(_childContract)),
                _childTokenId
            );
        }
        emit ReceivedChild(_from, _tokenId, _childContract, _childTokenId);
    }

    ////////////////////////////////////////////////////////
    // ERC165 implementation
    ////////////////////////////////////////////////////////

    /**
     * @dev See {IERC165-supportsInterface}.
     * The interface id 0x1bc995e4 is added. The spec claims it to be the interface id of IERC998ERC721TopDown.
     * But it is not.
     * It is added anyway in case some contract checks it being compliant with the spec.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165, ERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC998ERC721TopDown).interfaceId ||
            interfaceId == type(IERC998ERC721TopDownEnumerable).interfaceId ||
            interfaceId == 0x1bc995e4 ||
            super.supportsInterface(interfaceId);
    }

    ////////////////////////////////////////////////////////
    // Last State Hash
    ////////////////////////////////////////////////////////

    /**
     * Update the state hash of tokenId and all its ancestors.
     * @param tokenId token id
     * @param childReference generalization of a child contract adddress
     * @param value new balance of ERC20, childTokenId of ERC721 or a child's state hash (if childContract==address(this))
     */
    function _updateStateHash(
        uint256 tokenId,
        uint256 childReference,
        uint256 value
    ) private {
        uint256 _newStateHash = uint256(
            keccak256(
                abi.encodePacked(
                    tokenIdToStateHash[tokenId],
                    childReference,
                    value
                )
            )
        );
        tokenIdToStateHash[tokenId] = _newStateHash;
        while (tokenIdToTokenOwner[tokenId] == address(this)) {
            tokenId = childTokenOwner[address(this)][tokenId];
            _newStateHash = uint256(
                keccak256(
                    abi.encodePacked(
                        tokenIdToStateHash[tokenId],
                        uint256(uint160(address(this))),
                        _newStateHash
                    )
                )
            );
            tokenIdToStateHash[tokenId] = _newStateHash;
        }
    }

    function stateHash(uint256 tokenId) public view returns (uint256) {
        uint256 _stateHash = tokenIdToStateHash[tokenId];
        require(_stateHash > 0, "CTD: stateHash of _tokenId is zero");
        return _stateHash;
    }

    /**
     * @dev See {safeTransferFrom}.
     * Check the state hash and call safeTransferFrom.
     */
    function safeCheckedTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 expectedStateHash
    ) external {
        require(
            expectedStateHash == tokenIdToStateHash[tokenId],
            "CTD: stateHash mismatch (1)"
        );
        safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {transferFrom}.
     * Check the state hash and call transferFrom.
     */
    function checkedTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 expectedStateHash
    ) external {
        require(
            expectedStateHash == tokenIdToStateHash[tokenId],
            "CTD: stateHash mismatch (2)"
        );
        transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {safeTransferFrom}.
     * Check the state hash and call safeTransferFrom.
     */
    function safeCheckedTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 expectedStateHash,
        bytes calldata data
    ) external {
        require(
            expectedStateHash == tokenIdToStateHash[tokenId],
            "CTD: stateHash mismatch (3)"
        );
        safeTransferFrom(from, to, tokenId, data);
    }
}

