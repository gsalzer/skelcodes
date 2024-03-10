pragma solidity ^0.5.0;


contract Registry {
    address public owner = msg.sender;
    address public target;
    
    function setTarget(address newTarget) public {
        require(msg.sender == owner);
        target = newTarget;
    }
}
