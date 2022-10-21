//////////////////////////////////////////////////
//SYNLEV FEES PROXY CONTRACT V 1.0.0
//////////////////////////

pragma solidity >= 0.6.4;

import './ownable.sol';

contract synStakingProxy is Owned {

  address payable public feeRecipient;

  receive() external payable {}

  function forwardfees() public {
    require(feeRecipient != address(0));
    feeRecipient.transfer(address(this).balance);
  }

  function setFeeRecipient(address payable account) public onlyOwner() {
    feeRecipient = account;
  }
}

