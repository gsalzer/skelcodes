/* SPDX-License-Identifier: BUSL-1.1 */
/* Copyright © 2021 Fragcolor Pte. Ltd. */

pragma solidity ^0.8.7;

interface IVault {
    function deposit() external payable;

    function bootstrap(address entityContract, address fragmentsLibrary)
        external;
}

