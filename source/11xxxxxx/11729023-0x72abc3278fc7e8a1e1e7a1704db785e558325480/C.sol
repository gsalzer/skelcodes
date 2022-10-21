//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.8.0;



contract C   {
    
  function a() external view returns(bytes32){
    return blockhash(block.number-1);
  }
  // function c() public payable {

  // }
  function d() external view returns(uint){
    return address(this).balance;
  }
  function b() public{
    selfdestruct(msg.sender);
  }

}
