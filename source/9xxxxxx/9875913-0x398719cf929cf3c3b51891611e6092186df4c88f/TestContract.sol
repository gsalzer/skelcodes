/**
 * Verify contract with libraries
*/

pragma solidity ^0.4.16;

library LibraryTestContract {
    function test() returns (address) {
        return address(this);
    }
}

contract TestContract {
    function testFunction() constant returns (address) {
        return LibraryTestContract.test();
    }
}
