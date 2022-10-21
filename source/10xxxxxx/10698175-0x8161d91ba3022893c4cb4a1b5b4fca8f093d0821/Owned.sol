pragma solidity ^0.4.26;

contract Owned {
	
	address public owner;
	
    constructor() public
	{
		owner = msg.sender;
	}
	
    // This contract only defines a modifier but it will be used in derived contracts.
    modifier onlyOwner() {
        require(msg.sender == owner, "Owner required");
        _;
    }
}
