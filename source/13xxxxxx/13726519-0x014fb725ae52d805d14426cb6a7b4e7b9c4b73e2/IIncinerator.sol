// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

interface IIncinerator {

    function incinerate(address tokenAddr) external payable;
}

