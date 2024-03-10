/* SPDX-License-Identifier: BUSL-1.1 */
/* Copyright © 2021 Fragcolor Pte. Ltd. */

pragma solidity ^0.8.7;

interface IRezProxy {
    function bootstrapProxy(address newImplementation) external;
}

