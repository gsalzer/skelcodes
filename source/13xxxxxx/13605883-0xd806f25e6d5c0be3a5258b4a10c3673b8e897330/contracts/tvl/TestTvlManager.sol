// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IAssetAllocation} from "contracts/common/Imports.sol";
import {TvlManager} from "./TvlManager.sol";

contract TestTvlManager is TvlManager {
    constructor(address addressRegistry_) public TvlManager(addressRegistry_) {} // solhint-disable-line no-empty-blocks

    function testGetAssetAllocationIdCount(
        IAssetAllocation[] memory allocations
    ) external view returns (uint256) {
        return _getAssetAllocationIdCount(allocations);
    }

    function testGetAssetAllocationIds(IAssetAllocation[] memory allocations)
        external
        view
        returns (bytes32[] memory)
    {
        return _getAssetAllocationsIds(allocations);
    }

    function testGetAssetAllocations()
        external
        view
        returns (IAssetAllocation[] memory)
    {
        return _getAssetAllocations();
    }

    function testDecodeAssetAllocationId(bytes32 id)
        external
        pure
        returns (address, uint8)
    {
        return _decodeAssetAllocationId(id);
    }

    function testEncodeAssetAllocationId(
        address assetAllocation,
        uint8 tokenIndex
    ) external pure returns (bytes32) {
        return _encodeAssetAllocationId(assetAllocation, tokenIndex);
    }
}

