pragma solidity ^0.7.4;

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() public {
		totalSupply = 3000;
		name = "Svitanok coin";
		decimals = 4;
		symbol = "SVT";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}

