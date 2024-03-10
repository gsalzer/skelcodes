// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

abstract contract AaveConstants {
    string public constant BASE_NAME = "aave";

    address public constant LENDING_POOL_ADDRESS =
        0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;

    address public constant AAVE_ADDRESS =
        0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    address public constant STAKED_AAVE_ADDRESS =
        0x4da27a545c0c5B758a6BA100e3a049001de870f5;

    address public constant STAKED_INCENTIVES_CONTROLLER_ADDRESS =
        0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5;

    address public constant SUSD_ADDRESS =
        0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;
    string public constant SUSD_SYMBOL = "sUSD";
    uint8 public constant SUSD_DECIMALS = 18;
}

