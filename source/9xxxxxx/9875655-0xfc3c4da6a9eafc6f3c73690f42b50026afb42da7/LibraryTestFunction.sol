/**
 * Submitted for verification at Etherscan.io on 2017-11-28
 * 
 * Verify contract with libraries
*/

pragma solidity ^0.4.16;

library LibraryTestFunction {
    function test() returns (address) {
        return address(this);
    }
}
