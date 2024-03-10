pragma solidity ^0.5.0;

contract addition {
    address reservedSlot; //to prevent overwritting proxy implementation address
    uint256 public myNumber;
    
    function add() public {
        myNumber = myNumber + 1;
    }
}
