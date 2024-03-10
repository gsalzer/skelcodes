pragma solidity ^0.4.18;

import "./Ownable.sol";

/**
 * Base ERC721 token contract
 */
contract CoinBase is Ownable {
  // ERC-721: implementsERC721() public view returns (bool _implementsERC721)
  bool public constant implementsERC721 = true;

  mapping(address => uint256) public coinBalance;
  mapping(uint256 => address) public coinIdToOwner;
  mapping(uint256 => address) public coinIdToApprovedAddress;

  // Events
  event Transfer(address indexed from, address indexed to, uint256 coinId);
  event Approval(address indexed owner, address indexed approved, uint256 coinId);

  // ERC-20 Compatibility: balanceOf(address walletAddress) public view returns (uint256 balance)
  function balanceOf(address walletAddress) public view returns (uint256 balance) {
    return coinBalance[walletAddress];
  }

  // Basic ownership: ownerOf(uint256 coinId) public view returns (address walletAddress)
  function ownerOf(uint256 coinId) public view returns (address walletAddress) {
    return coinIdToOwner[coinId];
  }

  // Basic ownership: approve(address newCoinOwner, uint256 coinId) public
  function approve(address newCoinOwner, uint256 coinId) public {
    require(coinIdToOwner[coinId] == msg.sender);
    coinIdToApprovedAddress[coinId] = newCoinOwner;
    Approval(msg.sender, newCoinOwner, coinId);
  }

  // Basic ownership: approveTransfer(address newCoinOwner, uint256 coinId) public
  function approveTransfer(address newCoinOwner, uint256 coinId) public {
    approve(newCoinOwner, coinId);
  }

  // Basic ownership: approvedFor(uint256 coinId) public view returns (address approvedWallet)
  function approvedFor(uint256 coinId) public view returns (address approvedWallet) {
    return coinIdToApprovedAddress[coinId];
  }

  // Basic ownership: getApproved(uint256 coinId) public view returns (address approvedWallet)
  function getApproved(uint256 coinId) public view returns (address approvedWallet) {
    return approvedFor(coinId);
  }

  // Basic ownership: takeOwnership(uint256 coinId) public
  function takeOwnership(uint256 coinId) public {
    require(coinIdToApprovedAddress[coinId] == msg.sender);
    address _from = coinIdToOwner[coinId];

    _transfer(_from, msg.sender, coinId);
  }

  // Basic ownership: transferFrom(address currentCoinOwner, address newCoinOwner, uint256 coinId) public
  function transferFrom(address currentCoinOwner, address newCoinOwner, uint256 coinId) public {
    require(newCoinOwner != address(0));
    require(newCoinOwner != address(this));
    require(coinIdToApprovedAddress[coinId] == msg.sender);
    require(coinIdToOwner[coinId] == currentCoinOwner);

    _transfer(currentCoinOwner, newCoinOwner, coinId);
  }

  // Basic ownership: transfer(address newCoinOwner, uint256 coinId) public
  function transfer(address newCoinOwner, uint256 coinId) public {
    require(newCoinOwner != address(0));
    require(newCoinOwner != address(this));
    require(coinIdToOwner[coinId] == msg.sender);

    _transfer(msg.sender, newCoinOwner, coinId);
  }

  // Basic ownership: _transfer(address currentCoinOwner, address newCoinOwner, uint256 coinId) internal
  function _transfer(address currentCoinOwner, address newCoinOwner, uint256 coinId) internal {
    if (coinIdToOwner[coinId] != address(0)) {
      delete coinIdToApprovedAddress[coinId];
      coinBalance[currentCoinOwner] -= 1;
    }
    coinIdToOwner[coinId] = newCoinOwner;
    coinBalance[newCoinOwner] += 1;
    Transfer(currentCoinOwner, newCoinOwner, coinId);
  }
}


