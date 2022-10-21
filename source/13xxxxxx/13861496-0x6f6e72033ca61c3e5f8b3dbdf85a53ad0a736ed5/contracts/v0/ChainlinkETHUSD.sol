/**
 * Submitted for verification at Etherscan.io on 2021-12-23
 */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

abstract contract ChainlinkETHUSD {
    address private _chainlinkDataFeed;

    function setChainlinkDataFeed(address dataFeed) external {
        require(_chainlinkDataFeed == address(0), "already set");

        _chainlinkDataFeed = dataFeed;
    }

    function getChainlinkDataFeed() external view returns (address) {
        return _chainlinkDataFeed;
    }

    function _convertEthToUsd(uint256 ethAmount)
        internal
        view
        virtual
        returns (uint256)
    {
        (
            uint80 roundId,
            int256 price,
            ,
            ,
            uint80 answeredInRound
        ) = AggregatorV3Interface(_chainlinkDataFeed).latestRoundData();

        require(answeredInRound == roundId, "ChainLink ETHUSD outdated");

        require(price != 0, "ChainLink ETHUSD is not working");

        return (ethAmount * uint256(price)) / 10**8;
    }

    // solhint-disable-next-line ordering
    uint256[49] private __gap;
}

// Copyright 2021 ToonCoin.COM
// http://tooncoin.com/license
// Full source code: http://tooncoin.com/sourcecode

