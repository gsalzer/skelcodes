pragma solidity 0.5.10;

contract Ownable {
    address payable public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor () internal {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
    
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
