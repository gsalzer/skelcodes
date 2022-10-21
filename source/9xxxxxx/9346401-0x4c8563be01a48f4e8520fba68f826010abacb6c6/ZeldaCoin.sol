pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract ZeldaCoin is ERC20Standard, Owned {
	constructor() public {
		initialSupply = 1000;
		totalSupply = initialSupply * 1000 ** uint256(decimals);
		name = "ZeldaCoin";
		decimals = 0;  
		symbol = "ZLD";
		version = "3.0";
		balances[msg.sender] = initialSupply;
	}
}

