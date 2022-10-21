// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20, INameIdentifier} from "contracts/common/Imports.sol";
import {
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {IMetaPool} from "contracts/protocols/curve/metapool/Imports.sol";

abstract contract CurveAlusdConstants is INameIdentifier {
    string public constant override NAME = "curve-alusd";

    // sometimes a metapool is its own LP token; otherwise,
    // you can obtain from `token` attribute
    IERC20 public constant LP_TOKEN =
        IERC20(0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c);

    // metapool primary underlyer
    IERC20 public constant PRIMARY_UNDERLYER =
        IERC20(0xBC6DA0FE9aD5f3b0d58160288917AA56653660E9);

    IERC20 public constant ALCX =
        IERC20(0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF);

    ILiquidityGauge public constant LIQUIDITY_GAUGE =
        ILiquidityGauge(0x9582C4ADACB3BCE56Fea3e590F05c3ca2fb9C477);

    // The metapool StableSwap contract
    IMetaPool public constant META_POOL =
        IMetaPool(0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c);
}

