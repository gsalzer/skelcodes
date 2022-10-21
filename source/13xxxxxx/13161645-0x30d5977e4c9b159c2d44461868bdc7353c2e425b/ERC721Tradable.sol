// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

import "./ContentMixin.sol";
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

  address public proxyRegistryAddress;
  uint256 private _currentTokenId = 0;

  constructor (
    string memory _name,
    string memory _symbol,
    address _proxyRegistryAddress
  ) ERC721(_name, _symbol) {
    proxyRegistryAddress = _proxyRegistryAddress;
    _initializeEIP712(_name);
  }

  /**
    * @dev calculates the next token ID based on value of _currentTokenId
    * @return uint256 for the next token ID
    */
  function _getNextTokenId() internal view returns (uint256) {
    return _currentTokenId.add(1);
  }

  /**
    * @dev increments the value of _currentTokenId
    */
  function _incrementTokenId() internal {
    _currentTokenId++;
  }

  function baseTokenURI() virtual public pure returns (string memory);

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
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(owner)) == operator) {
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

