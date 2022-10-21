// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {
    IAssetAllocation,
    IERC20,
    INameIdentifier
} from "contracts/common/Imports.sol";
import {IZap} from "./IZap.sol";
import {TestLpAccountStorage} from "./TestLpAccountStorage.sol";

contract TestZap is IZap, TestLpAccountStorage {
    string[] internal _sortedSymbols;

    constructor(string memory name) public {
        _name = name;
    }

    function deployLiquidity(uint256[] calldata amounts) external override {
        _deploysArray.push(amounts);
    }

    // TODO: push index in addition to amount
    function unwindLiquidity(uint256 amount, uint8) external override {
        _unwindsArray.push(amount);
    }

    function claim() external override {
        _claimsCounter += 1;
    }

    // solhint-disable-next-line func-name-mixedcase
    function NAME() external view override returns (string memory) {
        return _name;
    }

    // Order of token amounts
    function sortedSymbols() external view override returns (string[] memory) {
        return _sortedSymbols;
    }

    // solhint-disable-next-line no-unused-vars
    function getLpTokenBalance(address account)
        external
        view
        override
        returns (uint256)
    {
        return 444;
    }

    function assetAllocations()
        external
        view
        override
        returns (string[] memory)
    {
        return _assetAllocations;
    }

    function erc20Allocations()
        external
        view
        override
        returns (IERC20[] memory)
    {
        return _tokens;
    }

    function _setAssetAllocations(string[] memory allocationNames) public {
        _assetAllocations = allocationNames;
    }

    function _setErc20Allocations(IERC20[] memory tokens) public {
        _tokens = tokens;
    }
}

