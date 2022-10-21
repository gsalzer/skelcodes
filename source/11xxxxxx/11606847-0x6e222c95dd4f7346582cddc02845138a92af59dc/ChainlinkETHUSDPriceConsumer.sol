// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./AggregatorV3Interface.sol";
import "./SafeMath.sol";

contract ChainlinkETHUSDPriceConsumer {

    uint256 public decimals = 8;
    address public owner;

    AggregatorV3Interface internal priceFeed;

    constructor(address _address) public {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_address);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner may perform this action");
        _;
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (uint256) {
        (,int ethusdprice,,,) = priceFeed.latestRoundData();
        return uint256(ethusdprice);
    }


    function getDecimals() public view returns (uint8) {
        return priceFeed.decimals();
    }


}
