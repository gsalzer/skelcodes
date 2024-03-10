pragma solidity ^0.5.0 <0.6.0;

contract Ownable {
  address internal _ownerAddr;

  modifier onlyOwner {
    require(msg.sender == _ownerAddr, "this method is only for owner");
    _;
  }

  function updateOwner(address newOwner) public onlyOwner {
    _ownerAddr = newOwner;
  }
}

