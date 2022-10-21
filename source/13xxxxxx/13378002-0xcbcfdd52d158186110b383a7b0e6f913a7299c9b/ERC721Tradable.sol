// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

import "./ContextMixin.sol";
import "./NativeMetaTransaction.sol";
contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is ContextMixin, ERC721Enumerable, NativeMetaTransaction, Ownable {
    using SafeMath for uint256;

    address proxyRegistryAddress;
    uint256 private _currentTokenId = 0;
    
    mapping (address => uint256)public userMints;
    
    address private adminWallet;
    uint256 private NFTprice;
    
    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
        address _adminwallet,
        uint256 _price
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712(_name);
        adminWallet = _adminwallet;
        NFTprice = _price;
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to) public onlyOwner {
        uint256 newTokenId = _getNextTokenId();
        _mint(_to, newTokenId);
        _incrementTokenId();
    }
    // Update Price 
    function UpdatePrice(uint256 price) public onlyOwner {
        NFTprice = price;
    }
    // Change Owner Wallet
    function UpdateWallet(address _adminWallet) public onlyOwner {
        adminWallet = _adminWallet;
    }
    
    // Update Price 
    function GetPrice() public view returns (uint256) {
        return NFTprice;
    }
    
    
    
    function mintNFT(uint256 totalMints_)public payable {
        require(userMints[msg.sender].add(totalMints_) <= 10, "Single user can not buy more than 10 NFTs");
        require(NFTprice.mul(totalMints_) == msg.value, "insufficient funds provided");
        require(ERC721Enumerable.totalSupply() < 1000, "Total supply Should be less than 1000 NFT.");
        
        for (uint256 i = 0; i< totalMints_; i++){
        _mint(msg.sender, _getNextTokenId());
        _incrementTokenId();
        
        userMints[msg.sender] = userMints[msg.sender] + 1;
        }
        
        
        
        address payable wallet = payable(adminWallet);
        wallet.transfer(msg.value);

    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }
    
    function getNexttokenId()public view returns (uint256){
        return _getNextTokenId();
    }

    /**
     * @dev increments the value of _currentTokenId
     */
    function _incrementTokenId() private {
        _currentTokenId++;
    }

    function baseTokenURI() virtual public view returns (string memory);

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
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

        if (proxyRegistryAddress == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}
