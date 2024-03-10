// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Vault} from '../core/Vault.sol';
import {IERC20} from '@openzeppelin/contracts/contracts/token/ERC20/IERC20.sol';
import {VestedVaultBoardroom} from '../core/VestedVaultBoardroom.sol';

contract ArthArthBoardroomV2 is VestedVaultBoardroom {
    constructor(
        IERC20 cash_,
        Vault arthVault_,
        uint256 vestFor_
    ) VestedVaultBoardroom(cash_, arthVault_, vestFor_) {}
}

