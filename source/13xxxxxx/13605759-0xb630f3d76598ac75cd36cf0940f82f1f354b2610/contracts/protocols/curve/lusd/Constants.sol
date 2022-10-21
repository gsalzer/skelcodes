// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20, INameIdentifier} from "contracts/common/Imports.sol";
import {
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {IMetaPool} from "contracts/protocols/curve/metapool/Imports.sol";

abstract contract CurveLusdConstants is INameIdentifier {
    string public constant override NAME = "curve-lusd";

    // sometimes a metapool is its own LP token; otherwise,
    // you can obtain from `token` attribute
    IERC20 public constant LP_TOKEN =
        IERC20(0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA);

    // metapool primary underlyer
    IERC20 public constant PRIMARY_UNDERLYER =
        IERC20(0x5f98805A4E8be255a32880FDeC7F6728C6568bA0);

    ILiquidityGauge public constant LIQUIDITY_GAUGE =
        ILiquidityGauge(0x9B8519A9a00100720CCdC8a120fBeD319cA47a14);

    IMetaPool public constant META_POOL =
        IMetaPool(0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA);
}

