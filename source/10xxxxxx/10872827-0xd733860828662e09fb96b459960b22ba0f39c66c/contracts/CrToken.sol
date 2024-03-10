// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";

contract CrToken is Initializable, ERC20PresetMinterPauserUpgradeSafe {
    uint256 private _totalSupply;

    function initialize() public initializer {
        ERC20PresetMinterPauserUpgradeSafe.initialize("Cryptomind", "CR");
        _setupDecimals(8);
        _totalSupply = totalSupply();

        _mint(msg.sender, 2000000000 * (10**8));
    }
}

