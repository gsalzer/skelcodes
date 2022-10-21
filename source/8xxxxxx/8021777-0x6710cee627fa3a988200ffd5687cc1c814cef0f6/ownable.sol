pragma solidity ^0.5.7;

/**
* @title Ownable
* @dev The Ownable contract has an owner address, and provides basic authorization control
* functions, this simplifies the implementation of "user permissions".
*/
contract Ownable {
	address public owner;
	address public newOwner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	/**
	* @dev Throws if called by any account other than the owner.
	*/
	modifier onlyOwner() {
		require(isOwner(), "Ownable: caller is not the owner");
		_;
	}

	/**
	* @return true if `msg.sender` is the owner of the contract.
	*/
	function isOwner() public view returns (bool) {
		return msg.sender == owner;
	}

	/**
	* @dev Allows the current owner to relinquish control of the contract.
	* It will not be possible to call the functions with the `onlyOwner`
	* modifier anymore.
	* @notice Renouncing ownership will leave the contract without an owner,
	* thereby removing any functionality that is only available to the owner.
	*/
	function renounceOwnership() public onlyOwner {
		emit OwnershipTransferred(owner, address(0));
		owner = address(0);
	}

	/**
	* @dev Allows the current owner to transfer control of the contract to a newOwner.
	* @param _newOwner The address to transfer ownership to.
	*/
	function transferOwnership(address _newOwner) public onlyOwner {
		newOwner = _newOwner;
	}

	function acceptOwnership() public{
		require (newOwner == msg.sender, "Ownable: only new Owner can accept");
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
		newOwner = address(0);
	}
}

