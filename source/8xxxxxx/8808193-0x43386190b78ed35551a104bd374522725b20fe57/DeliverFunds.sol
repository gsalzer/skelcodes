pragma solidity 0.5.12;

contract DeliverFunds {
    constructor(address payable target) public payable {
        selfdestruct(target);
    }
}
