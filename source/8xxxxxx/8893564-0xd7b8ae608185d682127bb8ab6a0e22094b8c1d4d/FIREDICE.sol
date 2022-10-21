//FIREBET - https://fire.date/spark/craps

pragma solidity ^0.4.23;

contract Ownable {
  address owner;
  constructor() public {
  owner = msg.sender;
  }

  modifier onlyOwner {
  require(msg.sender == owner);
  _;
  }
}

  contract Mortal is Ownable {
  function kill() public onlyOwner {
  selfdestruct(owner);
  }
}

  contract FIREDICE is Mortal{
  uint minBet = 1000000000;

  event Won(bool _status, uint _number1, uint _number2, uint _amount);

  constructor() payable public {}

  function() public { //fallback
    revert();
  }

  function Roll(uint _diceone, uint _dicetwo) payable public {
    require(_diceone > 0 && _diceone <= 6);
    require(_dicetwo > 0 && _dicetwo <= 6);
    require(msg.value >= minBet);
    uint256 rollone = block.number % 10 + 1;
    uint256 rolltwo = (block.number-1) % 10 + 1;
    uint totalroll = rollone + rolltwo;
    uint _totaldice = _diceone + _dicetwo;
    if (_totaldice == totalroll) {
      uint amountWon = msg.value;
      if(rollone==rolltwo) amountWon = msg.value*2;
      if(totalroll==2) amountWon = msg.value*8;
      if(totalroll==12) amountWon = msg.value*8;
      if(!msg.sender.send(amountWon)) revert();
      emit Won(true, rollone, rolltwo, amountWon);
    }
    else {
      emit Won(false, rollone, rolltwo, 0);
    }
  }

  function checkContractBalance() public view returns(uint) {
    return address(this).balance;
  }

  //Withdrawal function
  function collect(uint _amount) public onlyOwner {
    require(address(this).balance > _amount);
    owner.transfer(_amount);
  }
}
