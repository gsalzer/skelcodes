pragma solidity ^0.4.26;

library SafeMath
{
	function mul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256)
	{
		uint256 c = a / b;
		return c;
	}

	function divRound(uint256 a, uint256 b) internal pure returns (uint256)
	{
		uint256 c = (a + (b/2)) / b;
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256)
	{
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256)
	{
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}

	function absDiff(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return a > b ? a - b : a - b;
	}
}

contract Ownable
{
	address _owner;
	event LogOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor () internal
	{
		_owner = msg.sender;
		emit LogOwnershipTransferred(address(0), _owner);
	}

	function owner() public view returns (address)
	{
		return _owner;
	}

	modifier onlyOwner() {
		require(msg.sender == _owner);
		_;
	}

	function transferOwnership(address newOwner) public onlyOwner
	{
		require(newOwner != address(0));
		_owner = newOwner;
		emit LogOwnershipTransferred(_owner, newOwner);
	}
}

contract Destructable is Ownable
{
	function selfdestroy() public onlyOwner
	{
		selfdestruct(_owner);
	}
}

contract TimeSource
{
	uint32 private mockNow;

	function currentTime() public constant returns (uint32)
	{
		require(block.timestamp <= 0xFFFFFFFF);
		if(mockNow > 0)
			return mockNow;
		return uint32(block.timestamp);
	}

	function mockTime(uint32 t) public
	{
		require(block.number <= 3316029);
		mockNow = t;
	}
}

