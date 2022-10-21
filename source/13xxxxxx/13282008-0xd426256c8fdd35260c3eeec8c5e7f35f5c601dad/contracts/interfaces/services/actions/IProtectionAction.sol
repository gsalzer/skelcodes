// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {IAction} from "./IAction.sol";

interface IProtectionAction is IAction {
    /// sohint-disable-next-line func-name-mixedcase
    function slippageInBps() external view returns (uint256);
}

