pragma solidity 0.6.9;

contract Migrations {
    address public owner;
    uint256 public lastCompletedMigration;

    constructor() public {
        owner = msg.sender;
    }

    modifier restricted() {
        if (msg.sender == owner) _;
    }

    function setCompleted(uint256 completed) external restricted {
        lastCompletedMigration = completed;
    }

    function upgrade(address newAddress) external restricted {
        Migrations upgraded = Migrations(newAddress);
        upgraded.setCompleted(lastCompletedMigration);
    }
}

