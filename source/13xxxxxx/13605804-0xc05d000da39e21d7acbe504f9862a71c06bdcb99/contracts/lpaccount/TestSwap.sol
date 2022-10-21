// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {
    IAssetAllocation,
    IERC20,
    INameIdentifier
} from "contracts/common/Imports.sol";
import {ISwap} from "./ISwap.sol";
import {TestLpAccountStorage} from "./TestLpAccountStorage.sol";

contract TestSwap is ISwap, TestLpAccountStorage {
    constructor(string memory name) public {
        _name = name;
    }

    function swap(uint256 amount, uint256) external override {
        _swapsArray.push(amount);
    }

    // solhint-disable-next-line func-name-mixedcase
    function NAME() external view override returns (string memory) {
        return _name;
    }

    function erc20Allocations()
        external
        view
        override
        returns (IERC20[] memory)
    {
        return _tokens;
    }

    function _setErc20Allocations(IERC20[] memory tokens) public {
        _tokens = tokens;
    }
}

