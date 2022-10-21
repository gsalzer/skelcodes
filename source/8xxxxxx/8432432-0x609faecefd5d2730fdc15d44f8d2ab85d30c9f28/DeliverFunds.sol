pragma solidity 0.5.10;

contract DeliverFunds {
    constructor(address payable target) public payable {
        selfdestruct(target);
    }
}
