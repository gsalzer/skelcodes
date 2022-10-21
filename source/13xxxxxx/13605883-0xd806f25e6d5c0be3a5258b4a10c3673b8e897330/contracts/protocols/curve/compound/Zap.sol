// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAssetAllocation} from "contracts/common/Imports.sol";
import {SafeERC20, SafeMath} from "contracts/libraries/Imports.sol";
import {
    IOldStableSwap2 as IStableSwap,
    IDepositZap,
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {CurveCompoundConstants} from "./Constants.sol";
import {CurveGaugeZapBase} from "contracts/protocols/curve/common/Imports.sol";

contract CurveCompoundZap is CurveGaugeZapBase, CurveCompoundConstants {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    constructor()
        public
        CurveGaugeZapBase(
            DEPOSIT_ZAP_ADDRESS,
            LP_TOKEN_ADDRESS,
            LIQUIDITY_GAUGE_ADDRESS,
            10000,
            100,
            2
        ) // solhint-disable-next-line no-empty-blocks
    {}

    function assetAllocations() public view override returns (string[] memory) {
        string[] memory allocationNames = new string[](1);
        allocationNames[0] = NAME;
        return allocationNames;
    }

    function erc20Allocations() public view override returns (IERC20[] memory) {
        IERC20[] memory allocations = _createErc20AllocationArray(0);
        return allocations;
    }

    function _getVirtualPrice() internal view override returns (uint256) {
        address stableSwap = IDepositZap(SWAP_ADDRESS).curve();
        return IStableSwap(stableSwap).get_virtual_price();
    }

    function _getCoinAtIndex(uint256 i)
        internal
        view
        override
        returns (address)
    {
        return IDepositZap(SWAP_ADDRESS).underlying_coins(int128(i));
    }

    function _addLiquidity(uint256[] calldata amounts, uint256 minAmount)
        internal
        override
    {
        IDepositZap(SWAP_ADDRESS).add_liquidity(
            [amounts[0], amounts[1]],
            minAmount
        );
    }

    function _removeLiquidity(
        uint256 lpBalance,
        uint8 index,
        uint256 minAmount
    ) internal override {
        IERC20(LP_TOKEN_ADDRESS).safeApprove(SWAP_ADDRESS, 0);
        IERC20(LP_TOKEN_ADDRESS).safeApprove(SWAP_ADDRESS, lpBalance);
        IDepositZap(SWAP_ADDRESS).remove_liquidity_one_coin(
            lpBalance,
            index,
            minAmount
        );
    }
}

