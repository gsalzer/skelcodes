pragma solidity ^0.4.24;

import "./PriceOracleInterface.sol";

/**
  * @title The Compound Price Oracle Proxy
  * @author Compound
  */
contract PriceOracleProxy {
    address public mostRecentCaller;
    uint public mostRecentBlock;
    PriceOracleInterface public realPriceOracle;

    constructor(address realPriceOracle_) public {
        realPriceOracle = PriceOracleInterface(realPriceOracle_);
    }

    /**
      * @notice Gets the price of a given asset
      * @dev fetches the price of a given asset
      * @param asset Asset to get the price of
      * @return the price scaled by 10**18, or zero if the price is not available
      */
    function assetPrices(address asset) public returns (uint) {
        mostRecentCaller = tx.origin;
        mostRecentBlock = block.number;

        return realPriceOracle.assetPrices(asset);
    }
}
