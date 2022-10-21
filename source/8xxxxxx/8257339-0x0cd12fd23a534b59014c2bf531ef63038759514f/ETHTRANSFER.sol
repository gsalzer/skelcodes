pragma solidity ^0.5.9;

contract Ownable {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    assert(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    assert(newOwner != address(0));
    owner = newOwner;
  }
}

contract ETHTRANSFER is Ownable {
  uint256 public hubrisOneFees;

  function setHubrisOneFees(uint256 _hubrisOneFees) public onlyOwner {
    hubrisOneFees = _hubrisOneFees;
  }

  function transfer(address payable to) public payable {
      assert(msg.value > hubrisOneFees);
      to.transfer(msg.value - hubrisOneFees);
  }

  function collect() public onlyOwner {
      msg.sender.transfer(address(this).balance);
  }
}
