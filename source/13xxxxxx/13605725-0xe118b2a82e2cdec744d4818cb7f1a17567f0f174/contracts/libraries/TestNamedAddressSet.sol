// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IAssetAllocation} from "contracts/common/Imports.sol";
import {IZap} from "contracts/lpaccount/Imports.sol";

import {NamedAddressSet} from "./NamedAddressSet.sol";

contract TestNamedAssetAllocationSet {
    using NamedAddressSet for NamedAddressSet.AssetAllocationSet;

    NamedAddressSet.AssetAllocationSet private _set;

    function add(IAssetAllocation allocation) external {
        _set.add(allocation);
    }

    function remove(string memory name) external {
        _set.remove(name);
    }

    function contains(IAssetAllocation allocation)
        external
        view
        returns (bool)
    {
        return _set.contains(allocation);
    }

    function length() external view returns (uint256) {
        return _set.length();
    }

    function at(uint256 index) external view returns (IAssetAllocation) {
        return _set.at(index);
    }

    function get(string memory name) external view returns (IAssetAllocation) {
        return _set.get(name);
    }

    function names() external view returns (string[] memory) {
        return _set.names();
    }
}

contract TestNamedZapSet {
    using NamedAddressSet for NamedAddressSet.ZapSet;

    NamedAddressSet.ZapSet private _set;

    function add(IZap zap) external {
        _set.add(zap);
    }

    function remove(string memory name) external {
        _set.remove(name);
    }

    function contains(IZap zap) external view returns (bool) {
        return _set.contains(zap);
    }

    function length() external view returns (uint256) {
        return _set.length();
    }

    function at(uint256 index) external view returns (IZap) {
        return _set.at(index);
    }

    function get(string memory name) external view returns (IZap) {
        return _set.get(name);
    }

    function names() external view returns (string[] memory) {
        return _set.names();
    }
}

