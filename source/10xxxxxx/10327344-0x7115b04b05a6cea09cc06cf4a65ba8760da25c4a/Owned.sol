pragma solidity ^0.5.1;

contract Owned {
	address payable internal owner;

	constructor() internal {
		owner = msg.sender;
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address payable newOwner) public onlyOwner {
		owner = newOwner;
	}
}
