pragma solidity ^0.5.0;

contract Owned {
	address public owner;
	address public newOwner;
	event OwnershipTransferred(address indexed _from, address indexed _to);

	constructor () internal {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "Owned: caller is not contract owner");
		_;
	}

	function transferOwnership(address _newOwner) public onlyOwner {
		newOwner = _newOwner;
	}

	function acceptOwnership() public {
		require(msg.sender == newOwner, "Owned: caller is not new contract owner");
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
		newOwner = address(0);
	}
}

