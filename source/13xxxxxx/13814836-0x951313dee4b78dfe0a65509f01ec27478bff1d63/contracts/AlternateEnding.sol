// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "./opensea/ProxyRegistry.sol";

contract AlternateEnding is ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    using Address for address payable;

    uint256 public PRICE;
    uint256 public MAX_TOTAL_MINT;

    // Fair distribution, thundering-herd mitigation and gas-wars prevention
    uint256 public MAX_TOTAL_MINT_PER_ADDRESS;
    uint256 public MAX_ALLOWED_GAS_FEE;

    bool public isPreSaleActive;
    uint256 public _publicSaleTime = 0;
    bool public isPurchaseEnabled;
    string private _contractURI;
    string private _placeholderURI;
    string private _baseTokenURI;
    address private _openSeaProxyRegistryAddress;

    uint256 private _currentTokenId = 0;
    address[] _payees;
    uint256[] _shares;
    uint256 _totalShares;

    mapping(address => bool) private _preSaleAllowList;

    constructor(
        string memory name,
        string memory symbol,
        uint256 price,
        uint256 maxTotalMint,
        address openSeaProxyRegistryAddress,
        uint256 publicSaleTime,
        bool purchaseEnabled,
        bool presaleActive,
        uint256 maxTotalMintPerAddress
    ) ERC721(name, symbol) {
        PRICE = price;
        MAX_TOTAL_MINT = maxTotalMint;
        MAX_ALLOWED_GAS_FEE = 0;

        _openSeaProxyRegistryAddress = openSeaProxyRegistryAddress;

        _publicSaleTime = publicSaleTime;
        isPurchaseEnabled = purchaseEnabled;
        isPreSaleActive = presaleActive;
        MAX_TOTAL_MINT_PER_ADDRESS = maxTotalMintPerAddress;
    }

    function setSaleInformation(
      uint256 publicSaleTime, bool purchaseEnabled, bool presaleActive,
      uint256 maxTotalMintPerAddress
    ) external onlyOwner {
      _publicSaleTime = publicSaleTime;
      isPurchaseEnabled = purchaseEnabled;
      isPreSaleActive = presaleActive;
      MAX_TOTAL_MINT_PER_ADDRESS = maxTotalMintPerAddress;
    }

    function setPayoutInformation(
      address[] calldata payees, uint256[] calldata shares
    ) external onlyOwner {
      require(payees.length == shares.length, "Withdraw: payees and shares length mismatch");

      _totalShares = 0;
      for (uint256 i = 0; i < shares.length; i++) {
        _totalShares += shares[i];
      }

      _payees = payees;
      _shares = shares;
    }

    function setPublicSaleTime(uint256 publicSaleTime) external onlyOwner {
      _publicSaleTime = publicSaleTime;
    }

    function togglePreSale(bool isActive) external onlyOwner {
        isPreSaleActive = isActive;
    }

    function togglePurchaseEnabled(bool isActive) external onlyOwner {
        isPurchaseEnabled = isActive;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPlaceholderURI(string memory placeholderURI) external onlyOwner {
        _placeholderURI = placeholderURI;
    }

    function setContractURI(string memory uri) external onlyOwner {
        _contractURI = uri;
    }

    function setMaxAllowedGasFee(uint256 maxFeeGwei) external onlyOwner {
        MAX_ALLOWED_GAS_FEE = maxFeeGwei;
    }

    function setOpenSeaProxyRegistryAddress(address addr) external onlyOwner {
      _openSeaProxyRegistryAddress = addr;
    }

    function withdraw() external onlyOwner {
      require(_payees.length > 0, "Withdraw: no payees");

      uint256 currentBalance = address(this).balance;
      for (uint256 i = 0; i < _payees.length; i++) {
        payable(_payees[i]).transfer(currentBalance * _shares[i] / _totalShares);
      }
    }

    function contractURI() public view returns (string memory) {
      return _contractURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
      return bytes(_baseTokenURI).length > 0 ? string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId))) : _placeholderURI;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
    override
    public
    view
    returns (bool)
    {
      // Whitelist OpenSea proxy contract for easy trading.
      ProxyRegistry proxyRegistry = ProxyRegistry(_openSeaProxyRegistryAddress);
      if (address(proxyRegistry.proxies(owner)) == operator) {
        return true;
      }

      return super.isApprovedForAll(owner, operator);
    }

    function addToPreSaleAllowList(address[] calldata addresses) external onlyOwner {
      for (uint256 i = 0; i < addresses.length; i++) {
        require(addresses[i] != address(0), "Can't add the null address");

        _preSaleAllowList[addresses[i]] = true;
      }
    }

    function onPreSaleAllowList(address addr) external view returns (bool) {
      return _preSaleAllowList[addr];
    }

    function mint(address to, uint256 count) external nonReentrant onlyOwner {
      // Make sure minting is allowed
      requireMintingConditions(to, count);

      for (uint256 i = 0; i < count; i++) {
        uint256 newTokenId = _getNextTokenId();
        _safeMint(to, newTokenId);
        _incrementTokenId();
      }
    }

    /**
     * Accepts required payment and mints a specified number of tokens to an address.
     * This method also checks if direct purchase is enabled.
     */
    function purchase(uint256 count) public payable nonReentrant {
      require(!msg.sender.isContract(), 'BASE_COLLECTION/CONTRACT_CANNOT_CALL');
      requireMintingConditions(msg.sender, count);

      require(isPurchaseEnabled, 'BASE_COLLECTION/PURCHASE_DISABLED');

      require(
        (_publicSaleTime != 0 && _publicSaleTime < block.timestamp) || (isPreSaleActive && _preSaleAllowList[msg.sender]),
        "BASE_COLLECTION/CANNOT_MINT"
      );

      // Sent value matches required ETH amount
      require(PRICE * count <= msg.value, 'BASE_COLLECTION/INSUFFICIENT_ETH_AMOUNT');

      for (uint256 i = 0; i < count; i++) {
        uint256 newTokenId = _getNextTokenId();
        _safeMint(msg.sender, newTokenId);
        _incrementTokenId();
      }
    }

    function transferFromBulk(
        address from,
        address to,
        uint256[] memory tokenIds
    ) public virtual {
        for (uint256 i = 0; i < tokenIds.length; i++) {
          //solhint-disable-next-line max-line-length
          require(_isApprovedOrOwner(_msgSender(), tokenIds[i]), "ERC721: transfer caller is not owner nor approved");
          _transfer(from, to, tokenIds[i]);
        }
    }

    function requireMintingConditions(address to, uint256 count) internal view {
      require(totalSupply() + count <= MAX_TOTAL_MINT, "BASE_COLLECTION/EXCEEDS_MAX_SUPPLY");

      uint totalMintFromAddress = balanceOf(to) + count;
      require (totalMintFromAddress <= MAX_TOTAL_MINT_PER_ADDRESS, "BASE_COLLECTION/EXCEEDS_INDIVIDUAL_SUPPLY");

      if (MAX_ALLOWED_GAS_FEE > 0)
          require(tx.gasprice < MAX_ALLOWED_GAS_FEE * 1000000000, "BASE_COLLECTION/GAS_FEE_NOT_ALLOWED");
    }

    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    function _incrementTokenId() private {
        _currentTokenId++;
    }
}

