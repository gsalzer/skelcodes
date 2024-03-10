import "./SafeMath.sol";
// File: browser/PercentageCalculator.sol

//"SPDX-License-Identifier: MIT"
pragma solidity 0.6.2;


library PercentageCalculator {
	using SafeMath for uint256;

	/*
	Note: Percentages will be provided in thousands to represent 3 digits after the decimal point.
	The division is made by 100000 
	*/ 
	function div(uint256 _amount, uint256 _percentage) public pure returns(uint256) {
		return _amount.mul(_percentage).div(100000);
	}
}
