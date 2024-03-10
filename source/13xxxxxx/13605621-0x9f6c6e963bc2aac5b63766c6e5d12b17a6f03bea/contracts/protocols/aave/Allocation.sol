// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {ImmutableAssetAllocation} from "contracts/tvl/Imports.sol";
import {ApyUnderlyerConstants} from "contracts/protocols/apy.sol";

import {ILendingPool} from "./common/interfaces/ILendingPool.sol";
import {AaveConstants} from "./Constants.sol";
import {AaveAllocationBase} from "./common/AaveAllocationBase.sol";

contract AaveStableCoinAllocation is
    AaveAllocationBase,
    ImmutableAssetAllocation,
    AaveConstants,
    ApyUnderlyerConstants
{
    string public constant override NAME = BASE_NAME;

    function balanceOf(address account, uint8 tokenIndex)
        external
        view
        override
        returns (uint256)
    {
        address underlyer = addressOf(tokenIndex);
        return
            super.getUnderlyerBalance(
                account,
                ILendingPool(LENDING_POOL_ADDRESS),
                underlyer
            );
    }

    function _getTokenData()
        internal
        pure
        override
        returns (TokenData[] memory)
    {
        TokenData[] memory tokens = new TokenData[](4);
        tokens[0] = TokenData(DAI_ADDRESS, DAI_SYMBOL, DAI_DECIMALS);
        tokens[1] = TokenData(USDC_ADDRESS, USDC_SYMBOL, USDC_DECIMALS);
        tokens[2] = TokenData(USDT_ADDRESS, USDT_SYMBOL, USDT_DECIMALS);
        tokens[3] = TokenData(SUSD_ADDRESS, SUSD_SYMBOL, SUSD_DECIMALS);
        return tokens;
    }
}

