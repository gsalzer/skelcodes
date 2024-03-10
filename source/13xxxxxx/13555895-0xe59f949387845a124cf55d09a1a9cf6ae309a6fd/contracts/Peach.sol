// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./utils/MinterRoleUpgradeable.sol";

/*
────────────────────────────────────────────────────────────────────────────
─██████████████─██████████████─██████████████─██████████████─██████──██████─
─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░██──██░░██─
─██░░██████░░██─██░░██████████─██░░██████░░██─██░░██████████─██░░██──██░░██─
─██░░██──██░░██─██░░██─────────██░░██──██░░██─██░░██─────────██░░██──██░░██─
─██░░██████░░██─██░░██████████─██░░██████░░██─██░░██─────────██░░██████░░██─
─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░██─────────██░░░░░░░░░░██─
─██░░██████████─██░░██████████─██░░██████░░██─██░░██─────────██░░██████░░██─
─██░░██─────────██░░██─────────██░░██──██░░██─██░░██─────────██░░██──██░░██─
─██░░██─────────██░░██████████─██░░██──██░░██─██░░██████████─██░░██──██░░██─
─██░░██─────────██░░░░░░░░░░██─██░░██──██░░██─██░░░░░░░░░░██─██░░██──██░░██─
─██████─────────██████████████─██████──██████─██████████████─██████──██████─
────────────────────────────────────────────────────────────────────────────
*/

contract Peach is OwnableUpgradeable, MinterRoleUpgradeable, ERC20BurnableUpgradeable {
    function initialize() public initializer {
        __Ownable_init();
        __MinterRole_init();
        __ERC20_init("Peach of Immortality", "PEACH");
        __ERC20Burnable_init();
    }

    function mint(address _to, uint256 _amount) public onlyMinter {
        _mint(_to, _amount);
    }
}

