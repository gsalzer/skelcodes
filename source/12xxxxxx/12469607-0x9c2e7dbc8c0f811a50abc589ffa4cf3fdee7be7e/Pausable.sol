import "./Ownable.sol";

pragma solidity ^0.5.0;

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause( uint64 timestamp );
  event Unpause( uint64 timestamp );

  bool public paused = false;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused, 'CVXBX is currently paused!');
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused, 'CVXBX is not paused!');
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused returns (bool) {
    paused = true;
    emit Pause( uint64(now) );
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused returns (bool) {
    paused = false;
    emit Unpause( uint64(now) );
    return true;
  }
}

