pragma solidity 0.5.7;


contract Number {

  mapping(address => uint) public numberForAddress;

  function setNumber(uint number) external {
    numberForAddress[msg.sender] = number;
  }

}
