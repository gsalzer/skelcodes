pragma solidity ^0.5.0;

contract AdminBase {
  address public owner;
  mapping (address => bool) admins;

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () public {
    owner = msg.sender;
    admins[msg.sender] = true;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyowner() {
    require(isowner(), "AdminBase: caller is not the owner");
    _;
  }

  modifier onlyAdmin() {
    require(admins[msg.sender], "AdminBase: caller is not the Admin");
    _;
  }

  function addAdmin(address account) public onlyowner {
    admins[account] = true;
  }

  function removeAdmin(address account) public onlyowner {
    admins[account] = false;
  }

  /**
   * @dev Returns true if the caller is the current owner.
   */
  function isowner() public view returns (bool) {
    return msg.sender == owner;
  }

  function isAdmin() public view returns (bool) {
    return admins[msg.sender];
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferowner(address newowner)
  public onlyowner {
    owner = newowner;
  }
}

