pragma solidity ^0.5.0;

contract AdditionContract {
    function Addition(uint a, uint b) public view returns (uint) {
        return (a + b);
    }
}

contract simpleTestFor060 {
    uint256 public ab;
    
    function additionTest(uint _a, uint _b) public {
        ab = _a + _b;
    }
}
