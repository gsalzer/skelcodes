// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {INameIdentifier} from "contracts/common/Imports.sol";
import {
    Curve3PoolUnderlyerConstants
} from "contracts/protocols/curve/3pool/Constants.sol";

abstract contract CurveAaveConstants is
    Curve3PoolUnderlyerConstants,
    INameIdentifier
{
    string public constant override NAME = "curve-aave";

    address public constant STABLE_SWAP_ADDRESS =
        0xDeBF20617708857ebe4F679508E7b7863a8A8EeE;
    address public constant LP_TOKEN_ADDRESS =
        0xFd2a8fA60Abd58Efe3EeE34dd494cD491dC14900;
    address public constant LIQUIDITY_GAUGE_ADDRESS =
        0xd662908ADA2Ea1916B3318327A97eB18aD588b5d;

    address public constant STKAAVE_ADDRESS =
        0x4da27a545c0c5B758a6BA100e3a049001de870f5;
    address public constant ADAI_ADDRESS =
        0x028171bCA77440897B824Ca71D1c56caC55b68A3;
    address public constant AUSDC_ADDRESS =
        0xBcca60bB61934080951369a648Fb03DF4F96263C;
    address public constant AUSDT_ADDRESS =
        0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811;
}

