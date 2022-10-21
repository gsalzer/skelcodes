pragma solidity ^0.5.10;

contract Ownable {

  // Owner of the contract
  address payable public owner;
  address payable internal _newOwner;

    constructor() public {
        owner = msg.sender;
    }

  /**
  * @dev Event to show ownership has been transferred
  * @param previousOwner representing the address of the previous owner
  * @param newOwner representing the address of the new owner
  */
  event OwnershipTransferred(address previousOwner, address newOwner);


  /**
   * @dev Sets a new owner address
   */
  function setOwner(address payable newOwner) internal {
    _newOwner = newOwner;
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyOwner() {
    require(msg.sender == owner, "Not Owner");
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address payable newOwner) public onlyOwner {
    require(newOwner != address(0), "Invalid Address");
    setOwner(newOwner);
  }

  //this flow is to prevent transferring ownership to wrong wallet by mistake
  function acceptOwnership() public returns (address){
      require(msg.sender == _newOwner,"Invalid new owner");
      emit OwnershipTransferred(owner, _newOwner);
      owner = _newOwner;
      _newOwner = address(0);
      return owner;
  }
}
