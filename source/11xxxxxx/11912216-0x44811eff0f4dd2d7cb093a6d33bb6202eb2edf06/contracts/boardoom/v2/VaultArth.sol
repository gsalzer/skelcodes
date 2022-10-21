// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Vault} from '../core/Vault.sol';
import {IERC20} from '@openzeppelin/contracts/contracts/token/ERC20/IERC20.sol';

contract VaultArth is Vault {
    constructor(IERC20 cash_, uint256 lockIn_) Vault(cash_, lockIn_) {}
}

