// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

library SafeMath {

  function add(uint a, uint b) internal pure returns(uint) {
    uint c = a + b;
    require(c >= a, "Sum overflow!");
    return c;
  }

  function sub(uint a, uint b) internal pure returns(uint) {
    uint c = a - b;
    require(c <= a, "Sub underflow!");
    return c;
  }

  function mul(uint a, uint b) internal pure returns(uint) {
    if(a == 0) {
      return 0;
    }
    uint c = a * b;
    require(c / a == b, "Mul overflow!");
    return c;
  }
  
  function div(uint a, uint b) internal pure returns(uint) {
    uint c = a / b;
    return c;
  }

}
