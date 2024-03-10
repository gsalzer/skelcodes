// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

abstract contract ChainlinkETHUSD {
    /**
     * The address of Chainlink's ETHUSD data feed
     */
    address private _chainlinkDataFeed;

    /**
     * Sets the address of Chainlink's ETHUSD data feed. Can be done only once
     */
    function setChainlinkDataFeed(address dataFeed) external {
        require(_chainlinkDataFeed == address(0), "already set");

        _chainlinkDataFeed = dataFeed;
    }

    /**
     * Returns the address of Chainlink's ETHUSD data feed
     */
    function getChainlinkDataFeed() external view returns (address) {
        return _chainlinkDataFeed;
    }

    /**
     * Converts the given `ethAmount` to USD using the current exchange rate
     * taken from Chainlink ETHUSD data feed. Returned value is normalized to
     * 10**18.
     */
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

        require(answeredInRound >= roundId, "ChainLink ETHUSD outdated");

        require(price != 0, "ChainLink ETHUSD is not working");

        // Chainlink's USD rates has a 10^8 precision
        return (ethAmount * uint256(price)) / 10**8;
    }

    // Reserved storage space to allow for layout changes in the future.
    // solhint-disable-next-line ordering
    uint256[49] private __gap;
}

