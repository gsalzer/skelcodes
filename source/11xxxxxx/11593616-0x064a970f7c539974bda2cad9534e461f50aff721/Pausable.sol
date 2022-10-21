// SPDX-License-Identifier: MIT
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
 pragma solidity >=0.6.0 <0.8.0;
 
 import "./Ownable.sol";
 
 contract Pausable is Ownable {
  event Paused();
  event Unpaused();

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Paused();
  }

  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpaused();
  }
}
