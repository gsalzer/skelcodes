
pragma solidity ^0.6.4;

import "./BrightID.sol";

contract Sponsor {
 BrightID public brightID;
 bytes32 public context;

 constructor(BrightID _brightID, bytes32 _context) public {
   brightID = _brightID;
   context = _context;
 }

 fallback() external payable {
  sponsor(msg.sender);
 }

 // sponsor any address that sends a transaction to this contract.
 receive() external payable {
   sponsor(msg.sender);
 }

 // sponsor any address is provided by as an parameter.
 function sponsor(address add) public {
   brightID.sponsor(context, bytes32(uint(add)));
 }
}

