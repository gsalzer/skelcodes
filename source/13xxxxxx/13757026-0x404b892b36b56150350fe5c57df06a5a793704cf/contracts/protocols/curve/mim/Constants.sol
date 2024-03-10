// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20, INameIdentifier} from "contracts/common/Imports.sol";
import {
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {IMetaPool} from "contracts/protocols/curve/metapool/Imports.sol";

abstract contract CurveMimConstants is INameIdentifier {
    string public constant override NAME = "curve-mim";

    // sometimes a metapool is its own LP token; otherwise,
    // you can obtain from `token` attribute
    IERC20 public constant LP_TOKEN =
        IERC20(0x5a6A4D54456819380173272A5E8E9B9904BdF41B);

    // metapool primary underlyer
    IERC20 public constant PRIMARY_UNDERLYER =
        IERC20(0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3);

    IERC20 public constant SPELL =
        IERC20(0x090185f2135308BaD17527004364eBcC2D37e5F6);

    ILiquidityGauge public constant LIQUIDITY_GAUGE =
        ILiquidityGauge(0xd8b712d29381748dB89c36BCa0138d7c75866ddF);

    IMetaPool public constant META_POOL =
        IMetaPool(0x5a6A4D54456819380173272A5E8E9B9904BdF41B);
}

