// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20, INameIdentifier} from "contracts/common/Imports.sol";
import {
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {IMetaPool} from "contracts/protocols/curve/metapool/Imports.sol";
import {IOldDepositor} from "contracts/protocols/curve/metapool/Imports.sol";

abstract contract CurveUsdpConstants is INameIdentifier {
    string public constant override NAME = "curve-usdp";

    // sometimes a metapool is its own LP token; otherwise,
    // you can obtain from `token` attribute
    IERC20 public constant LP_TOKEN =
        IERC20(0x7Eb40E450b9655f4B3cC4259BCC731c63ff55ae6);

    // metapool primary underlyer
    IERC20 public constant PRIMARY_UNDERLYER =
        IERC20(0x1456688345527bE1f37E9e627DA0837D6f08C925);

    ILiquidityGauge public constant LIQUIDITY_GAUGE =
        ILiquidityGauge(0x055be5DDB7A925BfEF3417FC157f53CA77cA7222);

    IMetaPool public constant META_POOL =
        IMetaPool(0x42d7025938bEc20B69cBae5A77421082407f053A);

    IOldDepositor public constant DEPOSITOR =
        IOldDepositor(0x3c8cAee4E09296800f8D29A68Fa3837e2dae4940);
}

