pragma solidity >=0.4.22 <0.6.0;

contract Owned {
    address owner;
    address newOwner;

    constructor() internal {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function ChangeOwnership(address p_newOwner) external onlyOwner {
        newOwner = p_newOwner;
    }

    function AcceptOwnership() external {
        require(msg.sender == newOwner);
        owner = newOwner;
    }
}

