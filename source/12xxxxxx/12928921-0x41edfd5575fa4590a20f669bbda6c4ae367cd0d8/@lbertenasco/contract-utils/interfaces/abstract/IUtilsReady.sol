// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import '../utils/IGovernable.sol';
import '../utils/ICollectableDust.sol';
import '../utils/IPausable.sol';

interface IUtilsReady is IGovernable, ICollectableDust, IPausable {
}

