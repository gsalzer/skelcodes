pragma solidity 0.5.0;

import "./Ownable.sol";

contract Pauser is Ownable {
  
  /* Attributes */
  bool private _paused;

  /* Event Definition */
  event Paused (address indexed admin);
  event Unpaused (address indexed admin);


  constructor() internal {
    _paused = false;
  }

  /* GETTER MODULE */
  /* bool value to know if transfer is paused or not
   * true - contract is paused
   * false - contract not paused */
  function paused() public view returns(bool) {
    return _paused;
  }

  /* MODIFIED MODULE */
  /* to make function callable if contract is not paused */
  modifier onlyNotPaused() {
    require (!_paused, "Contract is Paused");
    _;
  }

  /* FUNCTIONAL MODULE */
  /* called by admin to pause ie. freeze all transfers */
  function pause() public onlyAdmin {
    _paused = true;

    emit Paused (msg.sender);
  }  

  /* called by admin to unpause ie. unfreeze all transfers */
  function unpause() public onlyAdmin {
    _paused = false;

    emit Paused (msg.sender);
  }
}

