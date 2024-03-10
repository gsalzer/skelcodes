pragma solidity ^0.5.4;


contract Ownable {

  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(isOwner(), "ONLY_OWNER");
    _;
  }

  function isOwner()
  public view
  returns (bool) {
    return msg.sender == _owner;
  }

  function renounceOwnership()
  public
  onlyOwner {
    emit OwnershipTransferred(_owner, address(0x01));
    _owner = address(0x01);
  }

  function transferOwnership(address newOwner)
  external
  onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner)
  internal {
    require(newOwner != address(0), "BAD_ADDRESS");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}
