pragma solidity ^0.5.0;

contract A {
    function gl(uint256 a) public view returns(uint256) {
        return gasleft()*a;
    }
}
