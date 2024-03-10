// contracts/BayCoin.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/presets/ERC20PresetFixedSupplyUpgradeable.sol";

contract BayCoin is ERC20PresetFixedSupplyUpgradeable {

    function initialize() public virtual initializer {
        uint256 initialSupply = 5 * 10 ** (13 + 18);

        __ERC20PresetFixedSupply_init("BayCoin", "BYC", initialSupply, msg.sender);
    }
}

