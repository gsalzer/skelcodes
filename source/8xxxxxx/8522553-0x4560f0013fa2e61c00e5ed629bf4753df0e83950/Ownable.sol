pragma solidity ^0.5.0;


contract Ownable {
    event TransferOwnership(address previousOwner, address newOwner);

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "msg.sender is not owner");
        _;
    }

    constructor () internal {
        owner = msg.sender;
        emit TransferOwnership(address(0), owner);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit TransferOwnership(owner, newOwner);
        owner = newOwner;
    }
}

