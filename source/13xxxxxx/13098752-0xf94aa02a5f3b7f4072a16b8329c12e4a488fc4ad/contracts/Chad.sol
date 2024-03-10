// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./IChad.sol";
import "./IProxyRegistry.sol";

contract Chad is Ownable, ERC721, IChad {
    error AmountExceedsMax(uint256 amount, uint256 maxAmount);
    error AmountExceedsMaxPerMint(uint256 amount, uint256 maxAmountPerMint);
    error NotEnoughEther(uint256 value, uint256 requiredEther);
    error SaleNotStarted(uint256 timestamp, uint256 startTime);

    // Thursday, 26 August 2021, 16:00 UTC
    uint256 public immutable saleStartTimestamp = 1629993600;

    // Max amount of public tokens
    uint256 public immutable maxPublicAmount = 9700;

    // Current amount of public tokens
    uint256 public currentPublicAmount;

    // Max amount of reserved tokens
    uint256 public immutable maxReservedAmount = 300;

    // Current amount of reserved tokens
    uint256 public currentReservedAmount;

    // Mint price of each token (1 ETH)
    uint256 public immutable price = 0.035 ether;

    // Max amount of NFT per one `mint()` function call
    uint256 public immutable maxAmountPerMint = 20;

    /// @inheritdoc IChad
    string public override contractURI;

    // Prefix of each tokenURI
    string internal baseURI;

    // Interface id of `contractURI()` function
    bytes4 private constant INTERFACE_ID_CONTRACT_URI = 0xe8a3d485;

    // OpenSea Proxy Registry address
    address internal constant OPEN_SEA_PROXY_REGISTRY = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    /// @notice Creates Chad NFTs, stores all the required parameters.
    /// @param contractURI_ Collection URI with collection metadata.
    /// @param baseURI_ Collection base URI prepended to each tokenURI.
    constructor(string memory contractURI_, string memory baseURI_) ERC721("Chad", "CHAD") {
        contractURI = contractURI_;
        baseURI = baseURI_;
    }

    /// @inheritdoc IChad
    function setBaseURI(string memory newBaseURI) external override onlyOwner {
        baseURI = newBaseURI;
    }

    /// @inheritdoc IChad
    function setContractURI(string memory newContractURI) external override onlyOwner {
        contractURI = newContractURI;
    }

    /// @inheritdoc IChad
    function mint(uint256 amount) external payable override {
        // solhint-disable not-rely-on-time
        if (block.timestamp < saleStartTimestamp)
            revert SaleNotStarted(block.timestamp, saleStartTimestamp);
        // solhint-enable not-rely-on-time
        if (amount > maxAmountPerMint) revert AmountExceedsMaxPerMint(amount, maxAmountPerMint);
        if (msg.value < price * amount) revert NotEnoughEther(msg.value, price * amount);
        uint256 newPublicAmount = currentPublicAmount + amount;
        if (newPublicAmount > maxPublicAmount)
            revert AmountExceedsMax(newPublicAmount, maxPublicAmount);

        currentPublicAmount = newPublicAmount;

        _safeMintMultiple(_msgSender(), amount);
    }

    /// @inheritdoc IChad
    function mintReserved(uint256 amount, address[] calldata recipients)
        external
        override
        onlyOwner
    {
        uint256 length = recipients.length;
        uint256 newReservedAmount = currentReservedAmount + length * amount;
        if (newReservedAmount > maxReservedAmount)
            revert AmountExceedsMax(newReservedAmount, maxReservedAmount);

        currentReservedAmount = newReservedAmount;

        for (uint256 i = 0; i < length; i++) {
            _safeMintMultiple(recipients[i], amount);
        }
    }

    /// @inheritdoc IChad
    function withdrawEther() external override onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return interfaceId == INTERFACE_ID_CONTRACT_URI || super.supportsInterface(interfaceId);
    }

    /// @inheritdoc ERC721
    function isApprovedForAll(address owner, address operator)
        public
        view
        override(ERC721, IERC721)
        returns (bool)
    {
        IProxyRegistry proxyRegistry = IProxyRegistry(OPEN_SEA_PROXY_REGISTRY);
        if (proxyRegistry.proxies(owner) == operator) return true;

        return super.isApprovedForAll(owner, operator);
    }

    /// @inheritdoc IChad
    function totalSupply() public view override returns (uint256) {
        return currentPublicAmount + currentReservedAmount;
    }

    /// @dev Helper function for minting multiple tokens
    function _safeMintMultiple(address recipient, uint256 amount) internal {
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(recipient, totalSupply());
        }
    }

    /// @inheritdoc ERC721
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}

