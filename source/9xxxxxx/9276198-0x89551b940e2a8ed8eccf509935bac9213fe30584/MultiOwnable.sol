pragma solidity ^0.5.5;

/**
 * @title MultiOwnable
 */
contract MultiOwnable {
  address public root;
  mapping (address => address) public owners;

  /**
  * @dev The Ownable constructor sets the original `owner` of the contract to the sender
  * account.
  */
  constructor() public {
    root = msg.sender;
    owners[root] = root;
  }

  /**
  * @dev check owner
  */
  modifier onlyOwner() {
    require(owners[msg.sender] != address(0), "permission error[onlyOwner]");
    _;
  }

   modifier onlyRoot() {
    require(msg.sender == root, "permission error[onlyRoot]");
    _;
  }

  /**
  * @dev add new owner
  */
  function newOwner(address _owner) external onlyOwner returns (bool) {
    require(_owner != address(0), "Invalid address.");
    require(owners[_owner] == address(0), "permission error[onlyOwner]");
    owners[_owner] = msg.sender;
    return true;
  }

  /**
    * @dev delete owner
    */
  function deleteOwner(address _owner) external onlyOwner returns (bool) {
    owners[_owner] = address(0);
    return true;
  }
}
