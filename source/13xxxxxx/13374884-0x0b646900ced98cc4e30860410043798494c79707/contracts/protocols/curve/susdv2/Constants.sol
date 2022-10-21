// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {INameIdentifier} from "contracts/common/Imports.sol";
import {
    Curve3PoolUnderlyerConstants
} from "contracts/protocols/curve/3pool/Constants.sol";

abstract contract CurveSusdV2Constants is
    Curve3PoolUnderlyerConstants,
    INameIdentifier
{
    string public constant override NAME = "curve-susdv2";

    address public constant STABLE_SWAP_ADDRESS =
        0xA5407eAE9Ba41422680e2e00537571bcC53efBfD;
    address public constant LP_TOKEN_ADDRESS =
        0xC25a3A3b969415c80451098fa907EC722572917F;
    address public constant LIQUIDITY_GAUGE_ADDRESS =
        0xA90996896660DEcC6E997655E065b23788857849;

    address public constant SUSD_ADDRESS =
        0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;
    address public constant SNX_ADDRESS =
        0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
}

