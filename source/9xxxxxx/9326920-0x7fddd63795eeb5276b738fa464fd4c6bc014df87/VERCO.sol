pragma solidity ^0.5.16;

import "./VERCO_ERC20_SmartContract.sol";

contract VERCO is ERC25BasicContract {
    using SafeMath for uint256;

constructor () public{
	totalSupply = 3000000000000000000000000; 
	name = "Vector Robotics";
		decimals = 18;
		symbol = "VERCO";
		version = "1.0";
	   balances[msg.sender] = totalSupply; 
	}
}

