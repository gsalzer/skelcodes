// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "contracts/common/Imports.sol";
import {SafeMath} from "contracts/libraries/Imports.sol";
import {ImmutableAssetAllocation} from "contracts/tvl/Imports.sol";

import {
    CTokenInterface,
    IStableSwap,
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";

import {
    CurveAllocationBase
} from "contracts/protocols/curve/common/Imports.sol";

import {CurveIronBankConstants} from "./Constants.sol";

contract CurveIronBankAllocation is
    CurveAllocationBase,
    ImmutableAssetAllocation,
    CurveIronBankConstants
{
    function balanceOf(address account, uint8 tokenIndex)
        public
        view
        override
        returns (uint256)
    {
        uint256 cyBalance =
            super.getUnderlyerBalance(
                account,
                IStableSwap(STABLE_SWAP_ADDRESS),
                ILiquidityGauge(LIQUIDITY_GAUGE_ADDRESS),
                IERC20(LP_TOKEN_ADDRESS),
                uint256(tokenIndex)
            );
        return unwrapBalance(cyBalance, tokenIndex);
    }

    function unwrapBalance(uint256 balance, uint8 tokenIndex)
        public
        view
        returns (uint256)
    {
        IStableSwap pool = IStableSwap(STABLE_SWAP_ADDRESS);
        CTokenInterface cyToken = CTokenInterface(pool.coins(tokenIndex));
        return balance.mul(cyToken.exchangeRateStored());
    }

    function _getTokenData()
        internal
        pure
        override
        returns (TokenData[] memory)
    {
        TokenData[] memory tokens = new TokenData[](3);
        tokens[0] = TokenData(DAI_ADDRESS, "DAI", 18);
        tokens[1] = TokenData(USDC_ADDRESS, "USDC", 6);
        tokens[2] = TokenData(USDT_ADDRESS, "USDT", 6);
        return tokens;
    }
}

