pragma solidity 0.5.17;

import "./AggregatorV3Interface.sol";

/**
 * @notice An aggregator that does one thing: return a fixed price, in fixed decimals, as set in the contructor.
 * @dev Must return Token/USD price and conform to AggregatorV3Interface for use with ChainlinkReporter
 */
contract FixedPriceAggregator is AggregatorV3Interface {
  /// @notice The number of decimals the fixed price is represented in
  uint8 public decimals;

  /// @notice The fixed price, in the decimals indicated, returned by this oracle
  int256 private price;

  /**
   * @param _decimals The number of decimals the fixed price is represented in
   * @param _price The fixed price, in the decimals indicated, to be returned by this oracle
   */
  constructor(uint8 _decimals, int256 _price) public {
    price = _price;
    decimals = _decimals;
  }

  /**
   * @return A description indicating this is a fixed price oracle
   */
  function description() external view returns (string memory) {
    return "Fixed price oracle";
  }

  /**
   * @return A version number of 0
   */
  function version() external view returns (uint256) {
    return 0;
  }

  /**
   * @param _roundId This parameter is ignored
   * @return roundId 0
   * @return answer The fixed price returned by this oracle, represented in appropriate decimals
   * @return startedAt 0
   * @return updatedAt Since price is fixed, we always return the current block timestamp
   * @return answeredInRound 0
   */
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    _roundId; // silence unused variable compiler warning
    return (uint80(0), price, uint256(0), block.timestamp, uint80(0));
  }

  /**
   * @return roundId 0
   * @return answer The fixed price returned by this oracle, represented in appropriate decimals
   * @return startedAt 0
   * @return updatedAt Since price is fixed, we always return the current block timestamp
   * @return answeredInRound 0
   */
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return (uint80(0), price, uint256(0), block.timestamp, uint80(0));
  }
}

