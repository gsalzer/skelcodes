pragma solidity >=0.4.21 <0.6.0;

contract BalanceChecker {
  address public owner;
 

  constructor() public {
    owner = msg.sender;
  }

  function check(address[] memory addresses) public view returns (bool){
    
 
    for(uint i=0; i<addresses.length;i++){
      if(addresses[i].balance != 0){
          return true;
      }
    }
    return false;
    
  }
}
