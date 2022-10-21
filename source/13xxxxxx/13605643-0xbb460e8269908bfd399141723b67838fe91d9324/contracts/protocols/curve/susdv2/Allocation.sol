// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "contracts/common/Imports.sol";
import {SafeMath} from "contracts/libraries/Imports.sol";
import {ImmutableAssetAllocation} from "contracts/tvl/Imports.sol";

import {
    IOldStableSwap4,
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";

import {
    OldCurveAllocationBase4
} from "contracts/protocols/curve/common/Imports.sol";

import {CurveSusdv2Constants} from "./Constants.sol";

contract CurveSusdv2Allocation is
    OldCurveAllocationBase4,
    ImmutableAssetAllocation,
    CurveSusdv2Constants
{
    function balanceOf(address account, uint8 tokenIndex)
        public
        view
        override
        returns (uint256)
    {
        return
            super.getUnderlyerBalance(
                account,
                IOldStableSwap4(STABLE_SWAP_ADDRESS),
                ILiquidityGauge(LIQUIDITY_GAUGE_ADDRESS),
                IERC20(LP_TOKEN_ADDRESS),
                tokenIndex
            );
    }

    function _getTokenData()
        internal
        pure
        override
        returns (TokenData[] memory)
    {
        TokenData[] memory tokens = new TokenData[](4);
        tokens[0] = TokenData(DAI_ADDRESS, "DAI", 18);
        tokens[1] = TokenData(USDC_ADDRESS, "USDC", 6);
        tokens[2] = TokenData(USDT_ADDRESS, "USDT", 6);
        tokens[3] = TokenData(SUSD_ADDRESS, "sUSD", 18);
        return tokens;
    }
}

