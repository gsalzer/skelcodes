/* SPDX-License-Identifier: BUSL-1.1 */
/* Copyright © 2021 Fragcolor Pte. Ltd. */

pragma solidity ^0.8.7;

import "openzeppelin-solidity/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-solidity/contracts/utils/Counters.sol";
import "openzeppelin-solidity/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/utils/structs/EnumerableSet.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./IFragment.sol";
import "./IVault.sol";
import "./IUtility.sol";
import "./RoyaltiesReceiver.sol";

struct FragmentInitData {
    uint160 fragmentId;
    uint96 maxSupply;
    address fragmentsLibrary;
    address payable vault;
    bool unique;
    bool updateable;
}

struct EntityData {
    uint64 blockNum;
}

contract Entity is ERC721Enumerable, Initializable, RoyaltiesReceiver {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;

    uint8 private constant _dataVersion = 0x1;

    Counters.Counter private _tokenIds;

    // mapping for fragments storage
    mapping(uint256 => EntityData) private _idToBlock;
    mapping(uint256 => bytes32) private _entityRefs;
    mapping(uint256 => EnumerableSet.UintSet) private _envToId;

    IFragment private _fragmentsLibrary;
    IVault private _vault;
    address private _delegate;
    uint256 private _publicMintingPrice;
    uint256 private _dutchStartBlock;
    uint256 private _dutchStep;
    uint160 private _fragmentId;
    uint96 private _maxSupply;
    uint96 private _maxPublicAmount;
    uint96 private _publicCap;
    uint8 private _publicMinting; // 0 no, 1 normal, 2 dutch auction
    bool private _uniqueEnv;
    bool private _canUpdate;

    uint8 private constant NO_PUB_MINTING = 0;
    uint8 private constant PUB_MINTING = 1;
    uint8 private constant DUTCH_MINTING = 2;

    string private _metaname;
    string private _desc;
    string private _url;

    event Updated(uint256 indexed id);

    constructor() ERC721("Entity", "FRAGe") {
        // this is just for testing - deployment has no constructor args (literally comment out)
        // Master fragment to entity
        _fragmentId = 0;
        // ERC721 - this we must make sure happens only and ever in the beginning
        // Of course being proxied it might be overwritten but if ownership is finally burned it's going to be fine!
        _fragmentsLibrary = IFragment(address(0));

        setupRoyalties(payable(0), FRAGMENT_ROYALTIES_BPS);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            _supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    // Use owner() as interface, but in this case it's just the controller NOT THE OWNER
    // this is useful only wrt OpenSea so far and other centralized exchanges
    // tl;dr until OpenSea becomes open to adopt EIP2981 we need to use owner() this way.
    function owner() public view returns (address) {
        IUtility ut = IUtility(_fragmentsLibrary.getUtilityLibrary());
        if (ut.overrideOwner()) {
            return _fragmentsLibrary.getController();
        } else {
            return fragmentOwner();
        }
    }

    function fragmentOwner() public view returns (address) {
        return _fragmentsLibrary.ownerOf(_fragmentId);
    }

    modifier onlyOwner() {
        require(fragmentOwner() == msg.sender, "Caller is not the owner");
        _;
    }

    function bootstrap(
        string calldata tokenName,
        string calldata tokenSymbol,
        FragmentInitData calldata params
    ) external initializer {
        _fragmentsLibrary = IFragment(params.fragmentsLibrary);

        // Master fragment to entity
        _fragmentId = params.fragmentId;

        // Vault
        _vault = IVault(params.vault);

        // ERC721 - this we must make sure happens only and ever in the beginning
        // Of course being proxied it might be overwritten but if ownership is finally burned it's going to be fine!
        _name = tokenName;
        _symbol = tokenSymbol;

        // Others
        _uniqueEnv = params.unique;
        _maxSupply = params.maxSupply;
        _canUpdate = params.updateable;

        setupRoyalties(payable(address(_vault)), FRAGMENT_ROYALTIES_BPS);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        IUtility ut = IUtility(_fragmentsLibrary.getUtilityLibrary());

        return
            ut.buildEntityMetadata(
                tokenId,
                _entityRefs[tokenId],
                address(this),
                uint256(_idToBlock[tokenId].blockNum)
            );
    }

    function contractURI() public view returns (string memory) {
        IUtility ut = IUtility(_fragmentsLibrary.getUtilityLibrary());
        return
            ut.buildEntityRootMetadata(
                _metaname,
                _desc,
                _url,
                address(_vault),
                FRAGMENT_ROYALTIES_BPS
            );
    }

    function setContractInfo(
        string calldata contractName,
        string calldata desc,
        string calldata url
    ) public onlyOwner {
        _metaname = contractName;
        _desc = desc;
        _url = url;
    }

    function getFragment() external view returns (uint160) {
        return _fragmentId;
    }

    function getLibrary() external view returns (address) {
        return address(_fragmentsLibrary);
    }

    function getVault() external view returns (address) {
        return address(_vault);
    }

    function getData(uint256 tokenId)
        external
        view
        returns (bytes32 environmentHash, uint256 blockNumber)
    {
        return (_entityRefs[tokenId], _idToBlock[tokenId].blockNum);
    }

    function containsId(uint160 dataHash, uint256 id)
        external
        view
        returns (bool)
    {
        return _envToId[dataHash].contains(id);
    }

    function setDelegate(address delegate) public onlyOwner {
        _delegate = delegate;
    }

    function update(
        bytes calldata signature,
        uint256 id,
        bytes calldata environment
    ) external {
        require(_canUpdate, "Update not allowed");
        require(ownerOf(id) == msg.sender, "Only owner can update");

        // All good authenticate now
        bytes32 hash = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    _getChainId(),
                    _fragmentId,
                    environment
                )
            )
        );
        require(
            _delegate != address(0x0) &&
                _delegate == ECDSA.recover(hash, signature),
            "Invalid signature"
        );

        bytes32 dataHash = keccak256(
            abi.encodePacked(_fragmentId, environment)
        );

        _envToId[uint256(dataHash)].add(id);

        _entityRefs[id] = dataHash;
        _idToBlock[id] = EntityData(uint64(block.number));

        emit Updated(id);
    }

    function _upload(bytes calldata environment, uint96 amount) internal {
        bytes32 dataHash = keccak256(
            abi.encodePacked(_fragmentId, environment)
        );

        for (uint256 i = 0; i < amount; i++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            require(
                _tokenIds.current() < _maxSupply,
                "Max minting limit has been reached"
            );

            require(
                !_uniqueEnv || _envToId[uint256(dataHash)].length() == 0,
                "Unique token already minted."
            );

            _envToId[uint256(dataHash)].add(newItemId);

            _mint(msg.sender, newItemId);

            _entityRefs[newItemId] = dataHash;
            _idToBlock[newItemId] = EntityData(uint64(block.number));
        }
    }

    function upload(bytes calldata environment, uint96 amount)
        external
        onlyOwner
    {
        _upload(environment, amount);
    }

    function _getChainId() private view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /*
        This is to allow public sales.
        We use a signature to allow an entity off chain to verify that the content is valid and vouch for it.
        If we want to skip that crafted address and random signatures can be used
    */
    function mint(
        bytes calldata signature,
        bytes calldata environment,
        uint96 amount
    ) external payable {
        // Sanity checks
        require(_publicMinting == PUB_MINTING, "Public minting not allowed");

        require(
            _tokenIds.current() + (amount - 1) < _publicCap,
            "Public minting limit has been reached"
        );

        require(amount <= _maxPublicAmount && amount > 0, "Invalid amount");

        uint256 price = amount * _publicMintingPrice;
        require(msg.value >= price, "Not enough value");

        // All good authenticate now
        bytes32 hash = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    _getChainId(),
                    _fragmentId,
                    environment,
                    amount
                )
            )
        );
        require(
            _delegate != address(0x0) &&
                _delegate == ECDSA.recover(hash, signature),
            "Invalid signature"
        );

        // pay royalties
        _vault.deposit{value: msg.value}();

        // mint it
        _upload(environment, amount);
    }

    /*
        This is to allow public auction sales.
        We use a signature to allow an entity off chain to verify that the content is valid and vouch for it.
        If we want to skip that crafted address and random signatures can be used
    */
    function bid(bytes calldata signature, bytes calldata environment)
        external
        payable
    {
        // Sanity checks
        require(_publicMinting == DUTCH_MINTING, "Auction bidding not allowed");

        require(
            _tokenIds.current() < _publicCap,
            "Minting limit has been reached"
        );

        // reduce price over time via blocks
        uint256 blocksDiff = block.number - _dutchStartBlock;
        uint256 price = _publicMintingPrice - (_dutchStep * blocksDiff);
        require(msg.value >= price, "Not enough value");

        // Authenticate
        bytes32 hash = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    _getChainId(),
                    _fragmentId,
                    environment
                )
            )
        );
        require(
            _delegate != address(0x0) &&
                _delegate == ECDSA.recover(hash, signature),
            "Invalid signature"
        );

        // pay royalties
        _vault.deposit{value: msg.value}();

        // mint it
        _upload(environment, 1);
    }

    function currentBidPrice() external view returns (uint256) {
        assert(_publicMinting == DUTCH_MINTING);
        // reduce price over time via blocks
        uint256 blocksDiff = block.number - _dutchStartBlock;
        uint256 price = _publicMintingPrice - (_dutchStep * blocksDiff);
        return price;
    }

    function isMarketOpen() external view returns (bool) {
        return
            _publicMinting != NO_PUB_MINTING &&
            _tokenIds.current() < _publicCap;
    }

    function setPublicSale(
        uint256 price,
        uint96 maxAmount,
        uint96 cap
    ) external onlyOwner {
        _publicMinting = PUB_MINTING;
        _publicMintingPrice = price;
        _maxPublicAmount = maxAmount;
        _publicCap = cap;
        assert(_publicCap <= _maxSupply);
    }

    function openDutchAuction(
        uint256 maxPrice,
        uint256 priceStep,
        uint96 slots
    ) external onlyOwner {
        _publicMinting = DUTCH_MINTING;
        _publicMintingPrice = maxPrice;
        _dutchStartBlock = block.number;
        _dutchStep = priceStep;
        _publicCap = slots;
        assert(_publicCap <= _maxSupply);
    }

    function stopMarket() external onlyOwner {
        _publicMinting = NO_PUB_MINTING;
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        // notice: fragmentOwner, not owner due to owner used for opensea workaround...
        IERC20(tokenAddress).safeTransfer(fragmentOwner(), tokenAmount);
    }

    function recoverETH(uint256 amount) external onlyOwner {
        // notice: fragmentOwner, not owner due to owner used for opensea workaround...
        payable(fragmentOwner()).transfer(amount);
    }
}

