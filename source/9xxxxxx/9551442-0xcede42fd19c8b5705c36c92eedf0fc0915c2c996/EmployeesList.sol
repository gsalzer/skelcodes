pragma solidity ^0.4.26;

import "./ESOPTypes.sol";

contract EmployeesList is ESOPTypes, Destructable
{
	event LogCreateEmployee(address indexed e, uint32 poolOptions, uint32 extraOptions, uint16 idx);
	event LogUpdateEmployee(address indexed e, uint32 poolOptions, uint32 extraOptions, uint16 idx);
	event LogChangeEmployeeState(address indexed e, EmployeeState oldState, EmployeeState newState);
	event LogRemoveEmployee(address indexed e);

	mapping (address => Employee) employees;
	address[] public addresses;

	function size() external constant returns (uint16)
	{
		return uint16(addresses.length);
	}

	function setEmployee(address e, uint32 issueDate,
						uint32 timeToSign, uint32 terminatedAt,
						uint32 fadeoutStarts, uint32 poolOptions,
						uint32 extraOptions, uint32 suspendedAt,
						EmployeeState state) external onlyOwner returns (bool isNew)
	{
		uint16 empIdx = employees[e].idx;
		if (empIdx == 0)
		{
			// new element
			uint addSize = addresses.length;
			require(addSize != 0xFFFF);

			isNew = true;
			empIdx = uint16(addSize + 1);
			addresses.push(e);

			emit LogCreateEmployee(e, poolOptions, extraOptions, empIdx);
		}
		else
		{
			isNew = false;
			emit LogUpdateEmployee(e, poolOptions, extraOptions, empIdx);
		}

		employees[e] = Employee({
			issueDate: issueDate,
			timeToSign: timeToSign,
			terminatedAt: terminatedAt,
			fadeoutStarts: fadeoutStarts,
			poolOptions: poolOptions,
			extraOptions: extraOptions,
			suspendedAt: suspendedAt,
			state: state,
			idx: empIdx
		});
	}

	function changeState(address e, EmployeeState state) external onlyOwner
	{
		require(employees[e].idx != 0);
		employees[e].state = state;
		emit LogChangeEmployeeState(e, employees[e].state, state);
	}

	function setFadeoutStarts(address e, uint32 fadeoutStarts) external onlyOwner
	{
		require(employees[e].idx != 0);
		employees[e].fadeoutStarts = fadeoutStarts;
		emit LogUpdateEmployee(e, employees[e].poolOptions, employees[e].extraOptions, employees[e].idx);
	}

	function removeEmployee(address e) external onlyOwner returns (bool)
	{
		uint16 empIdx = employees[e].idx;
		if (empIdx == 0)
			return false;

		delete employees[e];
		delete addresses[empIdx-1];
		emit LogRemoveEmployee(e);
		return true;
	}

	function terminateEmployee(address e, uint32 issueDate, uint32 terminatedAt, uint32 fadeoutStarts) external onlyOwner
	{
		Employee storage employee = employees[e];
		require(employee.idx != 0);

		employee.state = EmployeeState.Terminated;
		emit LogChangeEmployeeState(e, employee.state, EmployeeState.Terminated);
		employee.issueDate = issueDate;
		employee.terminatedAt = terminatedAt;
		employee.fadeoutStarts = fadeoutStarts;
		employee.suspendedAt = 0;
		emit LogUpdateEmployee(e, employee.poolOptions, employee.extraOptions, employee.idx);
	}

	function getEmployee(address e) external constant returns (uint32, uint32, uint32, uint32, uint32, uint32, uint32, EmployeeState)
	{
		Employee storage employee = employees[e];
		require(employee.idx != 0);

		return (employee.issueDate, employee.timeToSign, employee.terminatedAt, employee.fadeoutStarts,
			employee.poolOptions, employee.extraOptions, employee.suspendedAt, employee.state);
	}

	function hasEmployee(address e) external constant returns (bool)
	{
		return employees[e].idx != 0;
	}

	function getSerializedEmployee(address e) external constant returns (uint[9])
	{
		Employee memory employee = employees[e];
		require(employee.idx != 0);
		return serializeEmployee(employee);
	}
}

