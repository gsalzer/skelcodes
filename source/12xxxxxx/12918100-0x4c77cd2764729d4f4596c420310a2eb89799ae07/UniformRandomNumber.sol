pragma solidity ^0.7.6;

///**
// * @author Brendan Asselstine
// * @notice A library that uses entropy to select a random number within a bound.  Compensates for modulo bias.
// * @dev Thanks to https://medium.com/hownetworks/dont-waste-cycles-with-modulo-bias-35b6fdafcf94
// */
//library UniformRandomNumber {
//  /// @notice Select a random number without modulo bias using a random seed and upper bound
//  /// @param _entropy The seed for randomness
//  /// @param _upperBound The upper bound of the desired number
//  /// @return A random number less than the _upperBound
//  function uniform(uint256 _entropy, uint256 _upperBound) internal pure returns (uint256) {
//    require(_upperBound > 0, "UniformRand/min-bound");
//    uint256 negation = _upperBound & (~_upperBound + 1);
//    uint256 min = negation % _upperBound;
//    uint256 random = _entropy;
//    while (true) {
//      if (random >= min) {
//        break;
//      }
//      random = uint256(keccak256(abi.encodePacked(random)));
//    }
//    return random % _upperBound;
//  }
//}


library UniformRandomNumber {
  /// @notice Select a random number without modulo bias using a random seed and upper bound
  /// @param _entropy The seed for randomness
  /// @param _upperBound The upper bound of the desired number
  /// @return A random number less than the _upperBound
  function uniform(uint256 _entropy, uint256 _upperBound) internal pure returns (uint256) {
    require(_upperBound > 0, "UniformRand/min-bound");
    uint256 min = -_upperBound % _upperBound;
    uint256 random = _entropy;
    while (true) {
      if (random >= min) {
        break;
      }
      random = uint256(keccak256(abi.encodePacked(random)));
    }
    return random % _upperBound;
  }
}

