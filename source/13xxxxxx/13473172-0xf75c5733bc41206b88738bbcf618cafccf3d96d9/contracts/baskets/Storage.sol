// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

// import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../contracts-upgradeable/ERC20Upgradeable.sol";

contract Storage is PausableUpgradeable, ERC20Upgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    // What assets do the basket contain?
    address[] public assets;

    // What modules have been approved?
    mapping(address => bool) public approvedModules;
}

