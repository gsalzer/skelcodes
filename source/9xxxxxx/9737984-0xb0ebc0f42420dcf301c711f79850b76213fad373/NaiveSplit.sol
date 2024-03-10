pragma solidity ^0.4.6;

/* how to send to multiple addrs? in address box type in addresses and separte them with a comma.
EX: 0x3c914C5c25Ea166F6B7c8131879B892Ed2912C6A, 0x3c914C5c25Ea166F6B7c8131879B892Ed2912C6A

if anything goes wrong, and the eth stays in contract, please call the Succ function. it will succ everything from the contract
bear in mind that bots may be camping it and remove funds before you can.
*/

contract NaiveSplit {


  // emit events for real-time listeners and state history

  event LogReceived(address sender, uint amount);
  event LogSent(address beneficiary, uint amount);

  // split using commas pls
  function pay(address[] addresses) public payable returns(bool success)
  {
    if(msg.value==0 || addresses.length == 0) revert();

    uint split = msg.value / addresses.length;

    emit LogReceived(msg.sender, msg.value);

    for (uint i=0; i<addresses.length; i++) {
        addresses[i].transfer(split);
        emit LogSent(addresses[i], split);
    }
    return true;
  }
  function Succ() public returns(bool success){
      tx.origin.transfer(address(this).balance);
      return true;
  }
}
