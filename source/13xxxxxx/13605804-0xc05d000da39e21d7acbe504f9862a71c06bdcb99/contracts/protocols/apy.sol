// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

abstract contract ApyUnderlyerConstants {
    address public constant DAI_ADDRESS =
        0x6B175474E89094C44Da98b954EedeAC495271d0F;
    string public constant DAI_SYMBOL = "DAI";
    uint8 public constant DAI_DECIMALS = 18;

    address public constant USDC_ADDRESS =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    string public constant USDC_SYMBOL = "USDC";
    uint8 public constant USDC_DECIMALS = 6;

    address public constant USDT_ADDRESS =
        0xdAC17F958D2ee523a2206206994597C13D831ec7;
    string public constant USDT_SYMBOL = "USDT";
    uint8 public constant USDT_DECIMALS = 6;
}

