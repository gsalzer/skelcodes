// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20, INameIdentifier} from "contracts/common/Imports.sol";
import {
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {IMetaPool} from "contracts/protocols/curve/metapool/Imports.sol";
import {IOldDepositor} from "contracts/protocols/curve/metapool/Imports.sol";

abstract contract CurveUsdnConstants is INameIdentifier {
    string public constant override NAME = "curve-usdn";

    // sometimes a metapool is its own LP token; otherwise,
    // you can obtain from `token` attribute
    IERC20 public constant LP_TOKEN =
        IERC20(0x4f3E8F405CF5aFC05D68142F3783bDfE13811522);

    // metapool primary underlyer
    IERC20 public constant PRIMARY_UNDERLYER =
        IERC20(0x674C6Ad92Fd080e4004b2312b45f796a192D27a0);

    ILiquidityGauge public constant LIQUIDITY_GAUGE =
        ILiquidityGauge(0xF98450B5602fa59CC66e1379DFfB6FDDc724CfC4);

    IMetaPool public constant META_POOL =
        IMetaPool(0x0f9cb53Ebe405d49A0bbdBD291A65Ff571bC83e1);

    IOldDepositor public constant DEPOSITOR =
        IOldDepositor(0x094d12e5b541784701FD8d65F11fc0598FBC6332);
}

