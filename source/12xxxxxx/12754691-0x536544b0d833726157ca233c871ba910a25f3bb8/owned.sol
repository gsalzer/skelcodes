pragma solidity ^0.4.23;

contract owned {
    address public owner;
    
    constructor () public {
        owner = msg.sender;
    }
    modifier onlyowner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnerShip(address newOwer) public onlyowner {
        owner = newOwer;
    }
}
