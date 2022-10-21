pragma solidity ^0.5.0;

contract MasterCopy {

  address public masterCopy;
  event Upgraded(address masterCopy);

  function _changeMasterCopy(address _masterCopy)
  internal {
    require(_masterCopy != address(0), "Invalid master copy address provided");
    emit Upgraded(_masterCopy);
    masterCopy = _masterCopy;
  }
}

