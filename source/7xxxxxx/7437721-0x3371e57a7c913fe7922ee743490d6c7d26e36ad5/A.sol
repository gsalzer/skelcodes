pragma solidity ^0.5.0;

contract A {
    B public myB = new B();
}

contract B {
    function getBlock() public view returns (uint256) {
        return block.timestamp;
    }
}
