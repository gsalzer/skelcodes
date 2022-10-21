pragma solidity ^0.4.18;

import "./Ownable.sol";
import "./CoinBase.sol";


/**
 * ValentineCoin specific token methods contract
 */
contract TheValentineCoinBase is CoinBase {
  // Constants
  // ERC-20 Compatibility: name() constant returns (string name)
  string public constant name = "The Valentine Coin";
  // ERC-20 Compatibility: symbol() constant returns (string symbol)
  string public constant symbol = "VALENTINE";
  // ERC-20 Compatibility: totalSupply() constant returns (uint256 _totalSupply)
  uint256 public constant totalSupply = 33333;

  mapping(uint256 => string) public engravings;

  function engravingOf(uint256 coinId) public view returns (string coinEngraving) {
    return engravings[coinId];
  }

  // Engrave
  function engrave(uint256 coinId, string coinEngraving) public {
    require(ownerOf(coinId) == msg.sender);
    require(bytes(engravings[coinId]).length == 0);
    require(bytes(coinEngraving).length > 0);
    engravings[coinId] = coinEngraving;
  }
}

