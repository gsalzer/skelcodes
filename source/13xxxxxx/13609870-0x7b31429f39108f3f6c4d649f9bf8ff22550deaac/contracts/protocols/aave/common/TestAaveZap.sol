// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAssetAllocation} from "contracts/common/Imports.sol";

import {AaveBasePool} from "./AaveBasePool.sol";

contract TestAaveZap is AaveBasePool {
    string public constant override NAME = "aave-test";

    constructor(address underlyerAddress, address lendingAddress)
        public
        AaveBasePool(underlyerAddress, lendingAddress)
    // solhint-disable-next-line no-empty-blocks
    {

    }

    function getUnderlyerAddress() external view returns (address) {
        return UNDERLYER_ADDRESS;
    }

    function getLendingAddress() external view returns (address) {
        return POOL_ADDRESS;
    }

    function assetAllocations() public view override returns (string[] memory) {
        return new string[](0);
    }

    function erc20Allocations() public view override returns (IERC20[] memory) {
        IERC20[] memory allocations = new IERC20[](0);
        return allocations;
    }

    // solhint-disable-next-line no-empty-blocks
    function _deposit(uint256 amount) internal virtual override {}

    // solhint-disable-next-line no-empty-blocks
    function _withdraw(uint256 lpBalance) internal virtual override {}
}

