// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";
import "@chainlink/contracts/src/v0.8/Denominations.sol";
import "./interfaces/IPriceFeed.sol";

contract PriceFeed is IPriceFeed {
    address public registry;
    address public token;
    address public base;
    address public quote;

    /**
     * @dev Sets the values for {registry}, {token}, {base}, and {quote}.
     *
     * We retrieve price from ChainLink registry, and normally {token} and {base} should be the same.
     * Also, we currently only support ETH and USD as quote.
     */
    constructor(address _registry, address _token, address _base, address _quote) {
        // We only support ETH and USD quote.
        require(_quote == Denominations.ETH || _quote == Denominations.USD, "unsupport quote");

        // Make sure the aggregator exists.
        AggregatorV2V3Interface aggregator = FeedRegistryInterface(_registry).getFeed(_base, _quote);
        require(FeedRegistryInterface(_registry).isFeedEnabled(address(aggregator)), "aggregator not enabled");

        registry = _registry;
        token = _token;
        base = _base;
        quote = _quote;
    }

    /**
     * @notice Return the token. It should be the collateral token address from IB agreement.
     * @return the token address
     */
    function getToken() external override view returns (address) {
        return token;
    }

    /**
     * @notice Return the token latest price in USD.
     * @return the price, scaled by 1e18
     */
    function getPrice() external override view returns (uint) {
        uint price = getPriceFromChainlink(base, quote);
        if (quote == Denominations.ETH) {
            uint ethUsdPrice = getPriceFromChainlink(Denominations.ETH, Denominations.USD);
            price = price * ethUsdPrice / 1e18;
        }
        return price;
    }

    /**
     * @notice Get the token price from ChainLink.
     * @param _base The base
     * @param _quote The quote
     * @return the price, scaled by 1e18
     */
    function getPriceFromChainlink(address _base, address _quote) internal view returns (uint) {
        ( , int price, , , ) = FeedRegistryInterface(registry).latestRoundData(_base, _quote);
        require(price > 0, "invalid price");

        // Extend the decimals to 1e18.
        return uint(price) * 10**(18 - uint(FeedRegistryInterface(registry).decimals(_base, _quote)));
    }
}

