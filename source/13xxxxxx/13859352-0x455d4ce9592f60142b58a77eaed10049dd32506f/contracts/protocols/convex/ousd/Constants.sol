// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20, INameIdentifier} from "contracts/common/Imports.sol";
import {
    IBaseRewardPool
} from "contracts/protocols/convex/common/interfaces/Imports.sol";
import {
    IMetaPool,
    IOldDepositor
} from "contracts/protocols/curve/metapool/Imports.sol";

abstract contract ConvexOusdConstants is INameIdentifier {
    string public constant override NAME = "convex-ousd";

    uint256 public constant PID = 56;

    // sometimes a metapool is its own LP token; otherwise,
    // you can obtain from `token` attribute
    IERC20 public constant LP_TOKEN =
        IERC20(0x87650D7bbfC3A9F10587d7778206671719d9910D);

    // metapool primary underlyer
    IERC20 public constant PRIMARY_UNDERLYER =
        IERC20(0x2A8e1E676Ec238d8A992307B495b45B3fEAa5e86);

    IERC20 public constant OGN =
        IERC20(0x8207c1FfC5B6804F6024322CcF34F29c3541Ae26);

    IMetaPool public constant META_POOL =
        IMetaPool(0x87650D7bbfC3A9F10587d7778206671719d9910D);

    IBaseRewardPool public constant REWARD_CONTRACT =
        IBaseRewardPool(0x7D536a737C13561e0D2Decf1152a653B4e615158);
}

