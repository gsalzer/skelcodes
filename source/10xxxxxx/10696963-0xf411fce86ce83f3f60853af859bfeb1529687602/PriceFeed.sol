pragma solidity ^0.6.7;

import "./AggregatorInterface.sol";

contract PriceFeed {
    /**
     * Network: Rinkeby
     * Aggregator: ETH/USD
     * Address: 0x0bF4e7bf3e1f6D6Dc29AA516A33134985cC3A5aA
     */
    /**
     * Returns the latest price
     */
    function getLatestPrice(address _address) internal view returns (uint256) {
        AggregatorInterface priceFeed = AggregatorInterface(_address);
        int256 p = priceFeed.latestAnswer();
        require(p > 0, "Invalid price feed!");
        return uint256(p);
    }

    /**
     * Returns the timestamp of the latest price update
     */
    function getLatestPriceTimestamp(address _address)
        internal
        view
        returns (uint256)
    {
        AggregatorInterface priceFeed = AggregatorInterface(_address);
        return priceFeed.latestTimestamp();
    }
}

