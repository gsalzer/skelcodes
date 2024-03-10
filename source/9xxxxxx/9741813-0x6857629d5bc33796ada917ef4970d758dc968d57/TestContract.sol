pragma solidity ^0.5.0;

contract TestContract {

    uint256 public testInt;

    address public testAddress;

    /// @notice Test event
    event TestEvent();

    constructor(address _testAddress) public {
        testInt = 11;
        testAddress = _testAddress;
    }

    function setTestInt(uint256 value) public {
        testInt = value;
    }    
}
