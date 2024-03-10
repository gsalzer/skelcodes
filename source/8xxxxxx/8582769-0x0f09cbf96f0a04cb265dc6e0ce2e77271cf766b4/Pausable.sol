pragma solidity ^0.5.4;

contract Pausable{

  bool paused;

  event Paused();
  event Unpaused();

  modifier whenNotPaused(){
    require(!paused, "PAUSED");
    _;
  }

  modifier whenPaused(){
    require(paused, "NOT_PAUSED");
    _;
  }

  function _pause() internal {
    emit Paused();
    paused = true;
  }

  function _unpause() internal {
    emit Unpaused();
    paused = false;
  }

  function isPaused()
  public view
  returns(bool){
    return paused;
  }
}
