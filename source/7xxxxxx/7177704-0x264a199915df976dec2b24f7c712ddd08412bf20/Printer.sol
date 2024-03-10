pragma solidity ^0.5.3;


contract Printer {
    
     function print() public view returns(address) 
     { 
         return address(this);
     }

}
