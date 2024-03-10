// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20, INameIdentifier} from "contracts/common/Imports.sol";
import {
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {IMetaPool} from "contracts/protocols/curve/metapool/Imports.sol";

abstract contract CurveFraxConstants is INameIdentifier {
    string public constant override NAME = "curve-frax";

    // sometimes a metapool is its own LP token; otherwise,
    // you can obtain from `token` attribute
    IERC20 public constant LP_TOKEN =
        IERC20(0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B);

    // metapool primary underlyer
    IERC20 public constant PRIMARY_UNDERLYER =
        IERC20(0x853d955aCEf822Db058eb8505911ED77F175b99e);

    IERC20 public constant FXS =
        IERC20(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);

    ILiquidityGauge public constant LIQUIDITY_GAUGE =
        ILiquidityGauge(0x72E158d38dbd50A483501c24f792bDAAA3e7D55C);

    IMetaPool public constant META_POOL =
        IMetaPool(0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B);
}

