pragma solidity ^0.5.0;

import "./Ownable.sol";

contract AuthorizedInvestor is Ownable{

  event AuthorizedInvestorAdded(address indexed account);
  event AuthorizedInvestorRemoved(address indexed account);

  mapping (address => bool) authorizedinvestors;

  constructor() public Ownable(){
    authorizedinvestors[msg.sender] = true;
  }

  modifier onlyAuthorizedInvestor() {
    require(isAuthorizedInvestor(msg.sender), "Not authorized investor");
    _;
  }

  function isAuthorizedInvestor(address account) public view returns (bool) {
  //  require(account != address(0), "Roles: account is the zero address");
    return authorizedinvestors[account];
  }

  function addAuthorizedInvestor(address account) public onlyOwner {
 //   require(!isAuthorizedInvestor(account), "Roles: account already has role");
    authorizedinvestors[account] = true;
    emit AuthorizedInvestorAdded(account);
  }

  function removeAuthorizedInvestor(address account) public onlyOwner {
  //  require(isAuthorizedInvestor(account), "Roles: account does not have role");
    authorizedinvestors[account] = false;
    emit AuthorizedInvestorRemoved(account);
  }
}

