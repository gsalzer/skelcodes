pragma solidity ^0.5.0;

contract simplecontract {
    uint256 public a;
    
    function update(uint256 _a) public {
        a = _a;
    }
}
