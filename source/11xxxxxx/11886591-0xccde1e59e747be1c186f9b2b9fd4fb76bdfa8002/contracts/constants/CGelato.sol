// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {
    IGelatoGasPriceOracle
} from "../interfaces/gelato/IGelatoGasPriceOracle.sol";

IGelatoGasPriceOracle constant GELATO_GAS_PRICE_ORACLE = IGelatoGasPriceOracle(
    0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C
);

address constant GELATO_EXECUTOR_MODULE = 0x98edc8067Cc671BCAE82D36dCC609C3E4e078AC8;

address constant CONDITION_MAKER_VAULT_UNSAFE_OSM = 0xDF3CDd10e646e4155723a3bC5b1191741DD90333;

