pragma solidity ^0.5.7;

import "./ERC20StandartBurnable.sol";

contract RBXtoken is ERC20StandartBurnable {
	constructor() public {
		totalSupply = 1300000000000;
		name = "Richbit coin";
		decimals = 4;
		symbol = "RBX";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}
