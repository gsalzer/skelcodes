pragma solidity ^0.5.0;

contract A {
    function gl() public view returns(uint256) {
        return gasleft();
    }
}
