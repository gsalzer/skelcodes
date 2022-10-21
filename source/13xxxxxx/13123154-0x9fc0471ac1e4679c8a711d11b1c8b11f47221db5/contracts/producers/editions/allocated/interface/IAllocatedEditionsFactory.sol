// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {AllocatedEditionsStorage} from "../AllocatedEditionsStorage.sol";

interface IAllocatedEditionsFactory {
    function logic() external returns (address);

    // AllocatedEditions data
    function parameters()
        external
        returns (
            // NFT Metadata
            bytes memory nftMetaData,
            // Edition Data
            uint256 allocation,
            uint256 quantity,
            uint256 price,
            // Config
            bytes memory configData
        );
}

