pragma solidity ^0.4.26;

import './ESOPTypes.sol';
import './BaseOptionsConverter.sol';

contract ERC20OptionsConverter is BaseOptionsConverter, TimeSource
{
	using SafeMath for uint;

	address esopAddress;
	uint32 exercisePeriodDeadline;
	mapping(address => uint) internal balances;
	string public name;
	string public symbol;
	uint public totalSupply;

	uint32 public optionsConversionDeadline;

	event Transfer(address indexed from, address indexed to, uint value);

	modifier converting()
	{
		require (currentTime() < exercisePeriodDeadline);
		_;
	}

	modifier converted()
	{
		require (currentTime() >= optionsConversionDeadline);
		_;
	}

	function getESOP() public constant returns (address)
	{
		return esopAddress;
	}

	function getExercisePeriodDeadline() public constant returns(uint32)
	{
		return exercisePeriodDeadline;
	}

	function exerciseOptions(address employee, uint poolOptions, uint extraOptions, uint bonusOptions,
		bool agreeToAcceleratedVestingBonusConditions) public onlyESOP converting
	{
		uint options = poolOptions.add(extraOptions).add(bonusOptions);
		totalSupply = totalSupply.add(options);
		balances[employee] += options;
		emit Transfer(0, employee, options);
	}

	function transfer(address _to, uint _value) converted public
	{
		require(balances[msg.sender] >= _value);
		balances[msg.sender] -= _value;
		balances[_to] += _value;
		emit Transfer(msg.sender, _to, _value);
	}

	function balanceOf(address _owner) constant public returns (uint balance)
	{
		return balances[_owner];
	}

	function () payable public
	{
		revert();
	}

	constructor(address esop, uint32 exerciseDeadline, uint32 conversionDeadline, string tokenName, string tokenSymbol) public
	{
		esopAddress = esop;
		exercisePeriodDeadline = exerciseDeadline;
		optionsConversionDeadline = conversionDeadline;
		name = tokenName;
		symbol = tokenSymbol;
	}
}

