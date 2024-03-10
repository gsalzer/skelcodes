pragma solidity 0.5.16;

contract DeliverFunds {
    constructor(address payable target) public payable {
        selfdestruct(target);
    }
}

