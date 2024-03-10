// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {
    MetaPoolAllocationBase
} from "contracts/protocols/curve/metapool/Imports.sol";

import {CurveMimConstants} from "./Constants.sol";

contract CurveMimAllocation is MetaPoolAllocationBase, CurveMimConstants {
    constructor(address curve3PoolAllocation_)
        public
        MetaPoolAllocationBase(curve3PoolAllocation_)
    {} // solhint-disable-line no-empty-blocks

    function balanceOf(address account, uint8 tokenIndex)
        public
        view
        override
        returns (uint256)
    {
        return
            super.getUnderlyerBalance(
                account,
                META_POOL,
                LIQUIDITY_GAUGE,
                LP_TOKEN,
                uint256(tokenIndex)
            );
    }

    function _getTokenData()
        internal
        pure
        override
        returns (TokenData[] memory)
    {
        return _getBasePoolTokenData(address(PRIMARY_UNDERLYER), "MIM", 18);
    }
}

