pragma solidity ^0.4.23;

import "./MultiOwnable.sol";

/**
 * @title Basic token
 *  Basic version of StandardToken, with no allowances.
 */
contract Blacklisted is MultiOwnable {

  mapping(address => bool) public blacklist;

  /**
  *  Throws if called by any account other than the owner.
  */
  modifier notBlacklisted() {
    require(blacklist[msg.sender] == false);
    _;
  }

  /**
   *  Adds single address to blacklist.
   * @param _villain Address to be added to the blacklist
   */
  function addToBlacklist(address _villain) external onlyOwner {
    blacklist[_villain] = true;
  }

  /**
   *  Adds list of addresses to blacklist. Not overloaded due to limitations with truffle testing.
   * @param _villains Addresses to be added to the blacklist
   */
  function addManyToBlacklist(address[] _villains) external onlyOwner {
    for (uint256 i = 0; i < _villains.length; i++) {
      blacklist[_villains[i]] = true;
    }
  }

  /**
   *  Removes single address from blacklist.
   * @param _villain Address to be removed to the blacklist
   */
  function removeFromBlacklist(address _villain) external onlyOwner {
    blacklist[_villain] = false;
  }
}

