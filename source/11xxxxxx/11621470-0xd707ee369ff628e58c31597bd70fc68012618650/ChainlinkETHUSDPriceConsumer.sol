// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./AggregatorV3Interface.sol";
import "./SafeMath.sol";

contract ChainlinkETHUSDPriceConsumer {

    uint256 public currRoundId;
    uint256 public decimals = 8;
    address public owner;

    AggregatorV3Interface internal priceFeed;

    struct RoundData{
      uint256 roundId;
      uint256 price;
      uint256 timestamp;
      uint256 usd2cny;
    }
    mapping(uint256=>RoundData) roundInfo;

    constructor() public {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner may perform this action");
        _;
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (uint256) {
        // (,int ethusdprice,,,) = priceFeed.latestRoundData();
        return 470000000000;
        // (,uint256 ethusdprice,,,) = priceFeed.latestRoundData();
        // uint256 usd2cny = 642000000;
        // return ethusdprice.mul(usd2cny).div(decimals);
    }


    function getDecimals() public view returns (uint8) {
        return priceFeed.decimals();
    }


    function setPrice(uint256 _price,uint _usdcny,uint256 _timestamp) public onlyOwner{
      // (,int ethusdprice,,,) = priceFeed.latestRoundData();
      currRoundId++;
      roundInfo[currRoundId].price = _price; // ethcny
      roundInfo[currRoundId].timestamp = _timestamp;
      roundInfo[currRoundId].usd2cny = _usdcny;
    }
}
