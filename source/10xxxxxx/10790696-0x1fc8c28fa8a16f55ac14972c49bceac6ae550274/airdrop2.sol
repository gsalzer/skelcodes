pragma solidity ^0.4.26;


import "./IERC20.sol";

contract Airdrop{
  function airdrop(address[] memory toAirdrop,uint[] memory tokensToEach,address tokenAddress) public{
    require(toAirdrop.length==tokensToEach.length,"must have same number of addresses and payments");
    for(uint i=0;i<toAirdrop.length;i++){
      ERC20(tokenAddress).transferFrom(msg.sender,toAirdrop[i],tokensToEach[i]);
    }
  }
}

