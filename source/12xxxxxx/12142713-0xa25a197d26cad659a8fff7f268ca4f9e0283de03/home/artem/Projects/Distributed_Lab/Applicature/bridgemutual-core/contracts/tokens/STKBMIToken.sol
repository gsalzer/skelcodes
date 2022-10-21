// SPDX-License-Identifier: MIT
pragma solidity =0.7.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IContractsRegistry.sol";

import "../interfaces/tokens/ISTKBMIToken.sol";

contract STKBMIToken is ISTKBMIToken, ERC20Upgradeable, OwnableUpgradeable {		
	address public stakingContract;

	modifier onlyBMIStaking() {
		require(stakingContract == _msgSender(), "Caller is not the BMIStaking contract");
		_;
	}

	function __STKBMIToken_init() external initializer {   
		__Ownable_init();
		__ERC20_init("Staking BMI", "stkBMI");
  	}

	function setDependencies(IContractsRegistry _contractsRegistry) external onlyOwner {
    	stakingContract = _contractsRegistry.getBMIStakingContract();
	}

	function mint(address account, uint256 amount) public override onlyBMIStaking {
		_mint(account, amount);
	}

	function burn(address account, uint256 amount) public override onlyBMIStaking {
		_burn(account, amount);
	}
}

