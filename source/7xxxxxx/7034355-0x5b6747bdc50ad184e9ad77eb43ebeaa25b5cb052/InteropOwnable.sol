pragma solidity ^0.5.0 <0.6.0;

import "./Ownable.sol";

contract InteropOwnable is Ownable {
  mapping (address => bool) internal _interopOwners;

  modifier onlyInteropOwner {
    require(_interopOwners[msg.sender], "this method is only for interop owner");
    _;
  }

  function addInteropOwner(address newOwner) public onlyOwner {
    _interopOwners[newOwner] = true;
  }

  function removeInteropOwner(address newOwner) public onlyOwner {
    _interopOwners[newOwner] = false;
  }
}

