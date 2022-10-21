// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract PriceConsumerV3 is Ownable {
  using SignedSafeMath for int256;
  using SafeMath for uint256;
  using SafeCast for uint256;
  using SafeCast for int256;
  using SafeCast for uint8;

  AggregatorV3Interface internal priceFeed;

  constructor()
  public
  Ownable()
  {
    priceFeed = AggregatorV3Interface(address(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419));
  }

  function getLatestPrice()
  public
  view
  returns(uint256, uint256)
  {
    (
      uint80 roundId,
      int price,
      uint startedAt,
      uint timeStamp,
      uint80 answeredInRound
    ) = priceFeed.latestRoundData();

    uint256 result = price.toUint256() / (10 ** priceFeed.decimals().toUint256());
    uint256 response = 1 / result;

    return (result, response);
  }

}
