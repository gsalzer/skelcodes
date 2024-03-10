pragma solidity ^0.4.17;

// ----------------------------------------------------------------------------
// Token Configuration
//
// Copyright (c) 2017 OpenST Ltd.
// https://simpletoken.org/
//
// The MIT Licence.
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// Portions are:
// Copyright (c) 2018 Bixer Pte.Ltd.
// The MIT Licence.
// ----------------------------------------------------------------------------


contract SimpleTokenConfig {

    string  public constant TOKEN_SYMBOL   = "TOC";
    string  public constant TOKEN_NAME     = "TokenChat";
    uint8   public constant TOKEN_DECIMALS = 6;

    uint256 public constant DECIMALSFACTOR = 10**uint256(TOKEN_DECIMALS);
    uint256 public constant TOKENS_MAX     = 1200000000 * DECIMALSFACTOR;
}

