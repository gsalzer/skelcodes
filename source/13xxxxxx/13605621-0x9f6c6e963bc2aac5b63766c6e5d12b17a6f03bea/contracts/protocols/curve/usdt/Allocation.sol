// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "contracts/common/Imports.sol";
import {SafeMath} from "contracts/libraries/Imports.sol";
import {ImmutableAssetAllocation} from "contracts/tvl/Imports.sol";

import {CTokenInterface, IOldStableSwap3, ILiquidityGauge} from "contracts/protocols/curve/common/interfaces/Imports.sol";

import {OldCurveAllocationBase3} from "contracts/protocols/curve/common/Imports.sol";

import {CurveUsdtConstants} from "./Constants.sol";

contract CurveUsdtAllocation is
    OldCurveAllocationBase3,
    ImmutableAssetAllocation,
    CurveUsdtConstants
{
    function balanceOf(address account, uint8 tokenIndex)
        public
        view
        override
        returns (uint256)
    {
        uint256 balance = super.getUnderlyerBalance(
            account,
            IOldStableSwap3(STABLE_SWAP_ADDRESS),
            ILiquidityGauge(LIQUIDITY_GAUGE_ADDRESS),
            IERC20(LP_TOKEN_ADDRESS),
            tokenIndex
        );
        balance = unwrapBalance(balance, tokenIndex);
        return balance;
    }

    function unwrapBalance(uint256 balance, uint8 tokenIndex)
        public
        view
        returns (uint256)
    {
        // Testing becomes trickier if we need to call `unwrapBalance`
        // on some underlyers but not others, so we make it a "no-op"
        // for non-wrapped tokens.
        //
        // token order: cDAI, cUSDC, USDT
        if (tokenIndex == 2) {
            return balance;
        }
        IOldStableSwap3 pool = IOldStableSwap3(STABLE_SWAP_ADDRESS);
        CTokenInterface cyToken = CTokenInterface(pool.coins(tokenIndex));
        return balance.mul(cyToken.exchangeRateStored()).div(10**uint256(18));
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

