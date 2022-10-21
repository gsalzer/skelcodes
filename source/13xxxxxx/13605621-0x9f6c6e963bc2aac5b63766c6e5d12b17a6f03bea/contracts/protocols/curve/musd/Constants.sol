// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20, INameIdentifier} from "contracts/common/Imports.sol";
import {
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {IMetaPool} from "contracts/protocols/curve/metapool/Imports.sol";
import {IOldDepositor} from "contracts/protocols/curve/metapool/Imports.sol";

abstract contract CurveMusdConstants is INameIdentifier {
    string public constant override NAME = "curve-musd";

    // sometimes a metapool is its own LP token; otherwise,
    // you can obtain from `token` attribute
    IERC20 public constant LP_TOKEN =
        IERC20(0x1AEf73d49Dedc4b1778d0706583995958Dc862e6);

    // metapool primary underlyer
    IERC20 public constant PRIMARY_UNDERLYER =
        IERC20(0xe2f2a5C287993345a840Db3B0845fbC70f5935a5);

    ILiquidityGauge public constant LIQUIDITY_GAUGE =
        ILiquidityGauge(0x5f626c30EC1215f4EdCc9982265E8b1F411D1352);

    IMetaPool public constant META_POOL =
        IMetaPool(0x8474DdbE98F5aA3179B3B3F5942D724aFcdec9f6);

    IOldDepositor public constant DEPOSITOR =
        IOldDepositor(0x803A2B40c5a9BB2B86DD630B274Fa2A9202874C2);
}

