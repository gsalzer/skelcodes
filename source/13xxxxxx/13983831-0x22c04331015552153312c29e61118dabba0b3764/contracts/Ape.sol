// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Tradable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Ape is ERC721Tradable {
    bool public salePublicIsActive;
    bool public saleWhitelistIsActive;
    uint256 public maxByMint;
    uint256 public maxSupply;
    uint256 public maxPublicSupply;
    uint256 public maxReservedSupply;
    uint256 public fixedPrice;
    address public daoAddress;
    string internal baseTokenURI;

    mapping(address => uint256) internal whitelist;

    using Counters for Counters.Counter;
    Counters.Counter private _totalPublicSupply;
    Counters.Counter private _totalReservedSupply;
    
    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721Tradable(_name, _symbol, _proxyRegistryAddress) {
        maxByMint = 2;
        maxSupply = 10000;
        maxReservedSupply = 50;  
        maxPublicSupply = maxSupply - maxReservedSupply;
        fixedPrice = 0.075 ether;
        daoAddress = 0x050F30bd067ac136B471Ed7CB7e7BE05cA11d779;
        baseTokenURI = "https://radioactiveapes.io/api/meta/1/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://radioactiveapes.io/api/contract/1";
    }

    function _mintN(uint numberOfTokens) private {
        require(numberOfTokens <= maxByMint, "Max mint exceeded");
        require(_totalPublicSupply.current() + numberOfTokens <= maxPublicSupply, "Max supply reached");
        for(uint i = 0; i < numberOfTokens; i++) {
            _totalPublicSupply.increment();
            _safeMint(msg.sender, this.totalPublicSupply());
        }
    }

    function mintPublic(uint numberOfTokens) external payable {
        require(salePublicIsActive, "Sale not active");
        require(fixedPrice * numberOfTokens <= msg.value, "Eth val incorrect");
        _mintN(numberOfTokens);
    }

    function mintWhitelist(uint numberOfTokens) external payable {
        require(saleWhitelistIsActive, "Whitelist sale not active");
        require(this.isWhitelisted(msg.sender) > 0, "Must be whitelisted");
        require(fixedPrice * numberOfTokens <= msg.value, "Eth val incorrect");
        whitelist[msg.sender] = 0;
        _mintN(numberOfTokens);
    }

    function mintReserved(address _to, uint numberOfTokens) external onlyOwner {
        require(_totalReservedSupply.current() + numberOfTokens <= maxReservedSupply, "Max supply reached");
        for(uint i = 0; i < numberOfTokens; i++) {
            _totalReservedSupply.increment();
            _safeMint(_to, maxPublicSupply + this.totalReservedSupply());
        }
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }

    function totalSupply() public view returns (uint256) {
        return _totalPublicSupply.current() + _totalReservedSupply.current();
    }

    function totalPublicSupply() public view returns (uint256) {
        return _totalPublicSupply.current();
    }

    function totalReservedSupply() public view returns (uint256) {
        return _totalReservedSupply.current();
    }

    function flipSalePublicStatus() external onlyOwner {
        salePublicIsActive = !salePublicIsActive;
    }

    function flipSaleWhitelistStatus() external onlyOwner {
        saleWhitelistIsActive = !saleWhitelistIsActive;
    }

    function setDaoAddress(address _daoAddress) external onlyOwner {
        daoAddress = _daoAddress;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setFixedPrice(uint256 _fixedPrice) external onlyOwner {
        fixedPrice = _fixedPrice;
    }

    function setMaxByMint(uint256 _maxByMint) external onlyOwner {
        maxByMint = _maxByMint;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0);
        _withdraw(daoAddress, balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Tx failed");
    }

    function isWhitelisted(address _address) external view returns (uint256) {
        return whitelist[_address];
    }

    function addWhitelist(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = 1;
        }
    }

    function removeWhitelist(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = 0;
        }
    }
    
}
