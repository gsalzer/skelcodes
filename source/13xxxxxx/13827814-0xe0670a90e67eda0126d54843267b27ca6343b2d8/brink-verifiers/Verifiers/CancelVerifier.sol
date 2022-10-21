// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

/**
 *    ,,                           ,,                                
 *   *MM                           db                      `7MM      
 *    MM                                                     MM      
 *    MM,dMMb.      `7Mb,od8     `7MM      `7MMpMMMb.        MM  ,MP'
 *    MM    `Mb       MM' "'       MM        MM    MM        MM ;Y   
 *    MM     M8       MM           MM        MM    MM        MM;Mm   
 *    MM.   ,M9       MM           MM        MM    MM        MM `Mb. 
 *    P^YbmdP'      .JMML.       .JMML.    .JMML  JMML.    .JMML. YA.
 *
 *    CancelVerifier.sol :: 0xE0670a90E67eda0126D54843267b27Ca6343B2d8
 *    etherscan.io verified 2021-12-18
 */ 

import "../Libraries/Bit.sol";

/// @title Verifier for cancellation of messages signed with a bitmapIndex and bit
/// @notice Uses the Bit library to use the bit, which invalidates messages signed with the same bit
contract CancelVerifier {
  event Cancel (uint256 bitmapIndex, uint256 bit);

  /// @dev Cancels existing messages signed with bitmapIndex and bit
  /// @param bitmapIndex The bitmap index to use
  /// @param bit The bit to use
  function cancel(uint256 bitmapIndex, uint256 bit) external {
    Bit.useBit(bitmapIndex, bit);
    emit Cancel(bitmapIndex, bit);
  }
}

