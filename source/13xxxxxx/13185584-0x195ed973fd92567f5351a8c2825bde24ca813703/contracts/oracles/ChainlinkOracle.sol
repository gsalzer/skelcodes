// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.6;

import "../interfaces/IPriceOracle.sol";
import "../interfaces/AggregatorV3Interface.sol";

/// @title Implementation of an Oracle using ChainLink aggregators as a data source
contract ChainlinkOracle is IPriceOracle {
    AggregatorV3Interface public oracle;

    constructor (address oracleAddr) {
        require(oracleAddr != address(0), "oracle cannot be 0x0");
        oracle = AggregatorV3Interface(oracleAddr);
    }

    function getPrice() public view override returns (uint256) {
        (, int price, , ,) = oracle.latestRoundData();

        return uint256(price);
    }
}

