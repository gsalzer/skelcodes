// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {INameIdentifier} from "contracts/common/Imports.sol";
import {
    Curve3poolUnderlyerConstants
} from "contracts/protocols/curve/3pool/Constants.sol";

abstract contract CurveSaaveConstants is
    Curve3poolUnderlyerConstants,
    INameIdentifier
{
    string public constant override NAME = "curve-saave";

    address public constant STABLE_SWAP_ADDRESS =
        0xEB16Ae0052ed37f479f7fe63849198Df1765a733;
    address public constant LP_TOKEN_ADDRESS =
        0x02d341CcB60fAaf662bC0554d13778015d1b285C;
    address public constant LIQUIDITY_GAUGE_ADDRESS =
        0x462253b8F74B72304c145DB0e4Eebd326B22ca39;

    address public constant SUSD_ADDRESS =
        0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;

    address public constant STKAAVE_ADDRESS =
        0x4da27a545c0c5B758a6BA100e3a049001de870f5;
    address public constant ADAI_ADDRESS =
        0x028171bCA77440897B824Ca71D1c56caC55b68A3;
    address public constant ASUSD_ADDRESS =
        0x6C5024Cd4F8A59110119C56f8933403A539555EB;
}

