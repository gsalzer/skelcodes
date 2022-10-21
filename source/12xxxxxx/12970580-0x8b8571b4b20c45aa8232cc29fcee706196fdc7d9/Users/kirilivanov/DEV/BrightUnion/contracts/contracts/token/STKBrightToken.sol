// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "../interfaces/IContractsRegistry.sol";

import "../interfaces/token/ISTKBrightToken.sol";

contract STKBrightToken is ISTKBrightToken, ERC20Upgradeable {
	IContractsRegistry public contractsRegistry;

	modifier onlyBrightStaking() {
		require(contractsRegistry.getBrightStakingContract() == _msgSender(), "Caller is not the BrightStaking contract");
		_;
	}

	function initialize(IContractsRegistry _contractsRegistry) external initializer {
		__ERC20_init("Stake BRIGHT", "stkBRIGHT");

		contractsRegistry = _contractsRegistry;
  	}

	function mint(address account, uint256 amount) public override onlyBrightStaking {
		_mint(account, amount);
	}

	function burn(address account, uint256 amount) public override onlyBrightStaking {
		_burn(account, amount);
	}
}

