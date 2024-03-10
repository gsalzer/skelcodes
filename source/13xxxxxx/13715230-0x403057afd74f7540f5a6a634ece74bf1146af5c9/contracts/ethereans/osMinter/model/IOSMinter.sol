// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@ethereansos/swissknife/contracts/generic/model/ILazyInitCapableElement.sol";

interface IOSMinter is ILazyInitCapableElement {
    function mint(uint256 value, address receiver) external;
}
