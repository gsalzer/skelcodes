// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20, INameIdentifier} from "contracts/common/Imports.sol";
import {
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {IMetaPool} from "contracts/protocols/curve/metapool/Imports.sol";
import {IOldDepositor} from "contracts/protocols/curve/metapool/Imports.sol";

abstract contract CurveUstConstants is INameIdentifier {
    string public constant override NAME = "curve-ust";

    // sometimes a metapool is its own LP token; otherwise,
    // you can obtain from `token` attribute
    IERC20 public constant LP_TOKEN =
        IERC20(0x94e131324b6054c0D789b190b2dAC504e4361b53);

    // metapool primary underlyer
    IERC20 public constant PRIMARY_UNDERLYER =
        IERC20(0xa47c8bf37f92aBed4A126BDA807A7b7498661acD);

    ILiquidityGauge public constant LIQUIDITY_GAUGE =
        ILiquidityGauge(0x3B7020743Bc2A4ca9EaF9D0722d42E20d6935855);

    IMetaPool public constant META_POOL =
        IMetaPool(0x890f4e345B1dAED0367A877a1612f86A1f86985f);

    IOldDepositor public constant DEPOSITOR =
        IOldDepositor(0xB0a0716841F2Fc03fbA72A891B8Bb13584F52F2d);
}

