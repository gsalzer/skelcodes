pragma solidity 0.5.0;


contract Ownable {

  /* Attributes */
  address private _admin;

  /* Event Definition */
  event AdminOwnershipTransferred (address indexed oldAdmin, address indexed newAdmin);


  constructor() internal {
    _admin = msg.sender;
  }

  /* GETTER MODUlE */
  function admin() public view returns(address) {
    return _admin;
  }  

  /* MODIFIER MODULE */
  /* to make function callable only invoked by admin */
  modifier onlyAdmin() {
    require (isAdmin(), "Caller is not an admin");
    _;
  }

  /* FUNCTIONAL BLOCK */  
  function isAdmin() public view returns(bool) {
    return (msg.sender == _admin);
  }

  /* relinquish control of contract by setting admin to zero address
   * after this function call onlyAdmin modifier cannot executed */
  function relinquishOwnership() public onlyAdmin {
    emit AdminOwnershipTransferred (_admin, address(0));

    _admin = address(0);      // Setting the _admin variable to point null address
  } 

  /* transfer admin privilages to another address */
  function adminTransfer(address newAdmin) public onlyAdmin {
    require (newAdmin != address(0), "Invalid address detected");

    emit AdminOwnershipTransferred (_admin, newAdmin);  

    _admin = newAdmin;
  }  
}

