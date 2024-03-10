// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./FurLib.sol";

/// @title Dice
/// @author LFG Gaming LLC
/// @notice Math utility functions that leverage storage and thus cannot be pure
abstract contract Dice {
  uint32 private LAST = 0; // Re-seed for PRNG

  /// @notice A PRNG which re-seeds itself with block information & another PRNG
  /// @dev This is unit-tested with monobit (frequency) and longestRunOfOnes
  function roll(uint32 seed) internal returns (uint32) {
    LAST = uint32(uint256(keccak256(
      abi.encodePacked(block.timestamp, block.basefee, _prng(LAST == 0 ? seed : LAST)))
    ));
    return LAST;
  }

  /// @notice A PRNG based upon a Lehmer (Park-Miller) method
  /// @dev https://en.wikipedia.org/wiki/Lehmer_random_number_generator
  function _prng(uint32 seed) internal view returns (uint256) {
    unchecked {
      uint256 nonce = seed == 0 ? uint32(block.timestamp) : seed;
      return (nonce * 48271) % 0x7fffffff;
    }
  }
}

