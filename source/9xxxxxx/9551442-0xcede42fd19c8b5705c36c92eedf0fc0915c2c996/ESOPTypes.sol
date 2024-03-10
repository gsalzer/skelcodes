pragma solidity ^0.4.26;
import "./Types.sol";

contract ESOPTypes
{
	// enums are numbered starting from 0. NotSet is used to check for non existing mapping
	enum EmployeeState
	{
		NotSet,
		WaitingForSignature,
		Employed,
		Terminated,
		OptionsExercised
	}

	struct Employee
	{
		// when vesting starts
		uint32 issueDate;
		// wait for employee signature until that time
		uint32 timeToSign;
		// date when employee was terminated, 0 for not terminated
		uint32 terminatedAt;
		// when fade out starts, 0 for not set, initally == terminatedAt
		// used only when calculating options returned to pool
		uint32 fadeoutStarts;
		// poolOptions employee gets (exit bonus not included)
		uint32 poolOptions;
		// extra options employee gets
		uint32 extraOptions;
		// time at which employee got suspended, 0 - not suspended
		uint32 suspendedAt;
		// what is employee current status, takes 8 bit in storage
		EmployeeState state;
		// index in iterable mapping
		uint16 idx;
	}

	function serializeEmployee(Employee memory employee) internal pure returns(uint[9] emp)
	{
		assembly { emp := employee }
	}

	function deserializeEmployee(uint[9] serializedEmployee) internal pure returns (Employee memory emp)
	{
		assembly { emp := serializedEmployee }
	}
}

