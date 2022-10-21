// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAssetAllocation} from "contracts/common/Imports.sol";
import {
    IStableSwap,
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {Curve3poolConstants} from "./Constants.sol";
import {CurveGaugeZapBase} from "contracts/protocols/curve/common/Imports.sol";

contract Curve3poolZap is CurveGaugeZapBase, Curve3poolConstants {
    constructor()
        public
        CurveGaugeZapBase(
            STABLE_SWAP_ADDRESS,
            LP_TOKEN_ADDRESS,
            LIQUIDITY_GAUGE_ADDRESS,
            10000,
            100,
            3
        ) // solhint-disable-next-line no-empty-blocks
    {}

    function assetAllocations() public view override returns (string[] memory) {
        string[] memory allocationNames = new string[](1);
        allocationNames[0] = NAME;
        return allocationNames;
    }

    function erc20Allocations() public view override returns (IERC20[] memory) {
        return _createErc20AllocationArray(0);
    }

    function _getVirtualPrice() internal view override returns (uint256) {
        return IStableSwap(SWAP_ADDRESS).get_virtual_price();
    }

    function _getCoinAtIndex(uint256 i)
        internal
        view
        override
        returns (address)
    {
        return IStableSwap(SWAP_ADDRESS).coins(i);
    }

    function _addLiquidity(uint256[] calldata amounts, uint256 minAmount)
        internal
        override
    {
        IStableSwap(SWAP_ADDRESS).add_liquidity(
            [amounts[0], amounts[1], amounts[2]],
            minAmount
        );
    }

    function _removeLiquidity(
        uint256 lpBalance,
        uint8 index,
        uint256 minAmount
    ) internal override {
        require(index < 3, "INVALID_INDEX");
        IStableSwap(SWAP_ADDRESS).remove_liquidity_one_coin(
            lpBalance,
            index,
            minAmount
        );
    }
}

