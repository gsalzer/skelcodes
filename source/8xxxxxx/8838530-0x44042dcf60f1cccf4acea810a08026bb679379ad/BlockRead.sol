pragma solidity ^0.5.11;


contract BlockRead {
    uint param = 5;
    address admin;
    
    constructor() public {
        admin = msg.sender;
    }
    
    function readParam() public view returns(uint) {
        require (msg.sender == admin);
        return param;
    }
}
