// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./erc20permit-upgradeable/ERC20PermitUpgradeable.sol";

import "../interfaces/IContractsRegistry.sol";
import "../interfaces/tokens/ISTKBMIToken.sol";

import "../abstract/AbstractDependant.sol";

contract STKBMIToken is ISTKBMIToken, ERC20PermitUpgradeable, AbstractDependant {
    address public stakingContract;

    modifier onlyBMIStaking() {
        require(
            stakingContract == _msgSender(),
            "STKBMIToken: Caller is not the BMIStaking contract"
        );
        _;
    }

    function __STKBMIToken_init() external initializer {
        __ERC20_init("Staking BMI V2", "stkBMIV2");
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        stakingContract = _contractsRegistry.getBMIStakingContract();
    }

    function mint(address account, uint256 amount) public override onlyBMIStaking {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public override onlyBMIStaking {
        _burn(account, amount);
    }
}

