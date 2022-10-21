// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov (az@unit.xyz).
*/
pragma solidity ^0.7.6;

interface IWrappedToUnderlyingOracle {
    function assetToUnderlying(address) external view returns (address);
}

