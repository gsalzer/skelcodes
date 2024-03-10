// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20, INameIdentifier} from "contracts/common/Imports.sol";
import {
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {IMetaPool} from "contracts/protocols/curve/metapool/Imports.sol";

abstract contract CurveBusdv2Constants is INameIdentifier {
    string public constant override NAME = "curve-busdv2";

    // sometimes a metapool is its own LP token; otherwise,
    // you can obtain from `token` attribute
    IERC20 public constant LP_TOKEN =
        IERC20(0x4807862AA8b2bF68830e4C8dc86D0e9A998e085a);

    ILiquidityGauge public constant LIQUIDITY_GAUGE =
        ILiquidityGauge(0xd4B22fEdcA85E684919955061fDf353b9d38389b);

    // metapool primary underlyer
    IERC20 public constant PRIMARY_UNDERLYER =
        IERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53);

    IMetaPool public constant META_POOL =
        IMetaPool(0x4807862AA8b2bF68830e4C8dc86D0e9A998e085a);
}

