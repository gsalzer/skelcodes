pragma solidity ^0.5.4;

import "./ERC20.sol";
import "./TokenDetails.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./HasBlacklist.sol";
import "./MasterCopy.sol";

contract Token is MasterCopy, ERC20, TokenDetails, Ownable, Pausable, HasBlacklist{

  function setup(address __owner)
  external {
    require(owner() == address(0), "ALREADY_INITIALIZED");
    _transferOwnership(__owner);
    detail("Visible", "VSB", 18);
    _mint(owner(), 100000000000000000000000000);
  }

  function mint(uint256 value)
  external onlyOwner whenNotPaused {
    _mint(owner(), value);
  }

  function burn(uint256 value)
  external whenNotPaused {
    _burn(msg.sender, value);
  }

  function pause()
  external onlyOwner whenNotPaused {
    _pause();
  }

  function unpause()
  external onlyOwner whenPaused {
    _unpause();
  }

  function addToBlacklist(address addr)
  external onlyOwner {
    _addToBlacklist(addr);
  }

  function removeFromBlacklist(address addr)
  external onlyOwner {
    _removeFromBlacklist(addr);
  }

  function transfer(address to, uint256 value)
  public whenNotPaused
  returns (bool) {
    require(!isBlacklisted(msg.sender), "BLACKLISTED");
    return super.transfer(to, value);
  }

  function transferFrom(address from, address to, uint256 value)
  public whenNotPaused
  returns (bool) {
    require(!isBlacklisted(from), "BLACKLISTED");
    return super.transferFrom(from, to, value);
  }

  function approve(address spender, uint256 value)
  public whenNotPaused
  returns (bool) {
    require(!isBlacklisted(msg.sender), "BLACKLISTED");
    return super.approve(spender, value);
  }

  function upgrade(address _newImplementation)
  external onlyOwner{
    _changeMasterCopy(_newImplementation);
  }
}
