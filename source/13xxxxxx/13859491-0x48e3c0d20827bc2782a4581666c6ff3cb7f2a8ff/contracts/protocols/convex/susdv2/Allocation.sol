// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "contracts/common/Imports.sol";
import {SafeMath} from "contracts/libraries/Imports.sol";
import {ImmutableAssetAllocation} from "contracts/tvl/Imports.sol";

import {
    OldConvexAllocationBase
} from "contracts/protocols/convex/common/Imports.sol";

import {ConvexSusdv2Constants} from "./Constants.sol";
import {
    Curve3poolUnderlyerConstants
} from "contracts/protocols/curve/3pool/Constants.sol";

contract ConvexSusdv2Allocation is
    OldConvexAllocationBase,
    ImmutableAssetAllocation,
    ConvexSusdv2Constants,
    Curve3poolUnderlyerConstants
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
                STABLE_SWAP_ADDRESS,
                REWARD_CONTRACT_ADDRESS,
                LP_TOKEN_ADDRESS,
                uint256(tokenIndex)
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

