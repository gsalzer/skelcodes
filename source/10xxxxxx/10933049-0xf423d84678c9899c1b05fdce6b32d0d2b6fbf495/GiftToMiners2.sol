// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <=0.7.0;

contract GiftToMiners2 {

  event Gift(address giver, address miner, uint amount);

  constructor() public {
  }

  function makeAGift() payable public {
    block.coinbase.transfer(msg.value);
    emit Gift(msg.sender, block.coinbase, msg.value);
  }
}
