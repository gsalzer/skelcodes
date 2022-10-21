pragma solidity >=0.4.25 <0.7.0;

import "./ERC20Burnable.sol";


contract ERC20Token is ERC20Burnable {
	  string public constant name = "FUMGO";
		string public constant symbol = "FMG";
		uint8 public constant decimals = 18;

		/**
		* @dev Constructor that gives _initialBeneficiar all of existing tokens.
		*/
		constructor(address _initialBeneficiar) public {
				uint256 TOTAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));
				_mint(_initialBeneficiar, TOTAL_SUPPLY);
		}
}

