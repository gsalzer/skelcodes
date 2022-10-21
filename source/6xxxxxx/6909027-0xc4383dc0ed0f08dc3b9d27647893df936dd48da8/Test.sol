pragma solidity ^0.4.24;

contract Test {
    function A() public pure returns (bool) {
        require(false, "you shall not pass");
        return true;
    }
}
