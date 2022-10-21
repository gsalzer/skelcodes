pragma solidity ^0.5.11;

contract Ownable {
    address private _owner;
    address public pendingOwner;

    modifier onlyOwner() {
        require(msg.sender == _owner, "caller is not the owner");
        _;
    }

    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(_owner, pendingOwner);
        _owner = pendingOwner;
        pendingOwner = address(0);
    }
}
