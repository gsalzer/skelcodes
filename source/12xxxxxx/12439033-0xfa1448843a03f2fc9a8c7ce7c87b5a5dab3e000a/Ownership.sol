pragma solidity 0.5.17;

contract Ownership {

  address public owner;
  address[] public deputyOwners;

  mapping(address => bool) public isDeputyOwner;

  event OwnershipUpdated(address oldOwner, address newOwner);
  event DeputyOwnerUpdated(address _do, bool _isAdded);

  constructor() public {
    owner = msg.sender;
    deputyOwners = [msg.sender];
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;
  }

  modifier onlyDeputyOrOwner() {
    require(msg.sender == owner || isDeputyOwner[msg.sender], "Only owner or deputy owner is allowed");
    _;
  }


  /**
   * @dev Transfer the ownership to some other address.
   * new owner can not be a zero address.
   * Only owner can call this function
   * @param _newOwner Address to which ownership is being transferred
   */
  function updateOwner(address _newOwner)
    public
    onlyOwner
  {
    require(_newOwner != address(0x0), "Invalid address");
    owner = _newOwner;
    emit OwnershipUpdated(msg.sender, owner);
  }

  /**
    * @dev Add new deputy owner.
    * Only Owner can call this function
    * New Deputy should not be zero address
    * New Deputy should not be be already exisitng
    * emit DeputyOwnerUdpatd event
    * @param _newDO Address of new deputy owner
   */
  function addDeputyOwner(address _newDO)
    public
    onlyOwner
  {
    require(!isDeputyOwner[_newDO], "Deputy Owner already exists");
    require(_newDO != address(0), "Zero address not allowed");
    deputyOwners.push(_newDO);
    isDeputyOwner[_newDO] = true;
    emit DeputyOwnerUpdated(_newDO, true);
  }

  /**
    * @dev Remove an existing deputy owner.
    * Only Owner can call this function
    * Given address should be a deputy owner
    * emit DeputyOwnerUdpatd event
    * @param _existingDO Address of existing deputy owner
   */
  function removeDeputyOwner(address _existingDO)
    public
    onlyOwner
  {
    require(isDeputyOwner[_existingDO], "Deputy Owner does not exits");
    uint existingId;
    for(uint i=0; i<deputyOwners.length; i++) {
      if(deputyOwners[i] == _existingDO) existingId=i;
    }

    // swap this with last element
    deputyOwners[existingId] = deputyOwners[deputyOwners.length-1];
    delete deputyOwners[deputyOwners.length-1];
    deputyOwners.length--;
    isDeputyOwner[_existingDO] = false;
    emit DeputyOwnerUpdated(_existingDO, false);
  }

  /**
   * @dev Renounce the ownership.
   * This will leave the contract without any owner.
   * Only owner can call this function
   * @param _validationCode A code to prevent aaccidental calling of this function
   */
  function renounceOwnership(uint _validationCode)
    public
    onlyOwner
  {
    require(_validationCode == 123456789, "Invalid code");
    owner = address(0);
    emit OwnershipUpdated(msg.sender, owner);
  }
}
