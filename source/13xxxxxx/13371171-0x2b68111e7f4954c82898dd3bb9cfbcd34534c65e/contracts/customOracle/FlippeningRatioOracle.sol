// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

import "@chainlink/contracts/src/v0.5/interfaces/AggregatorV2V3Interface.sol";
import "synthetix-2.43.1/contracts/SafeDecimalMath.sol";
import "synthetix-2.43.1/contracts/Owned.sol";

contract FlippeningRatioOracle is Owned {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    AggregatorV2V3Interface internal firstMarketcap;
    AggregatorV2V3Interface internal secondMarketcap;

    constructor(
        address _owner,
        address _first,
        address _second
    ) public Owned(_owner) {
        firstMarketcap = AggregatorV2V3Interface(_first);
        secondMarketcap = AggregatorV2V3Interface(_second);
    }

    function getRatio() public view returns (uint) {
        uint firstPrice = uint(firstMarketcap.latestAnswer());
        uint secondPrice = uint(secondMarketcap.latestAnswer());

        return firstPrice.mul(1e18).div(secondPrice);
    }

    function setFirstMarketcap(address _marketcap) public onlyOwner {
        firstMarketcap = AggregatorV2V3Interface(_marketcap);
    }

    function setSecondMarketcap(address _marketcap) public onlyOwner {
        secondMarketcap = AggregatorV2V3Interface(_marketcap);
    }
}

