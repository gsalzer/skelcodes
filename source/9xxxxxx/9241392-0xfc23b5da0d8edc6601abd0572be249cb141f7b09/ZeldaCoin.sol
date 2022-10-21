pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract ZeldaCoin is ERC20Standard, Owned {
	constructor() public {
		initialSupply = 100000;
		totalSupply = initialSupply * 10 ** uint256(decimals);
		name = "ZeldaCoin";
		decimals = 18;  
		symbol = "ZLD";
		version = "2.0";
		balances[msg.sender] = initialSupply;
	}
}

