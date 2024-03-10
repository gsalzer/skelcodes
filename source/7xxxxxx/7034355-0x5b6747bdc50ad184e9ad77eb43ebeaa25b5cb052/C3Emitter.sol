pragma solidity ^0.5.0 <0.6.0;

interface C3Emitter {
  function fireTransferEvent(address from, address to, uint256 tokens) external;

  function fireApprovalEvent(address tokenOwner, address spender, uint tokens) external;
}

