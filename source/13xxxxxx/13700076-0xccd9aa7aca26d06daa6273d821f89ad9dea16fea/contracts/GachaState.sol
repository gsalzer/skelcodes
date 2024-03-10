// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.10;

/**
 * example:
 * 256 chips:   0 .. 99 , 100 .. 199 , 200 .. 255
 * 2 segments: |   0    |      1     |
 */
contract GachaState {
  mapping(uint256 => uint256) public segments;
  uint256 public segmentsCount;
  uint256 private _perSegmentSize = 100;
  uint256 private _playerMaintainSegmentOffset = 10;

  struct Chip {
    address player;
    uint96 amount;
  }
  mapping(uint256 => Chip) public chips;
  uint256 public chipsCount;

  uint256 public totalAmount;
  uint256 private _previousAmount;

  /**
   * stake ether without check amount
   */
  function _stake(Chip memory chip) internal {
    if (_checkMaintainSegment(_playerMaintainSegmentOffset)) {
      _performMaintainSegment();
    }

    chips[chipsCount] = chip;
    chipsCount += 1;
    totalAmount += chip.amount;
  }

  /**
   * refund all staked ether without check
   */
  function _refund(address sender, uint256[] calldata chipIndexes) internal returns (uint256) {
    uint128 currentRefundAmount;
    uint128 previousRefundAmount;

    for (uint256 i = 0; i < chipIndexes.length; i++) {
      uint256 chipIndex = chipIndexes[i];
      if (chips[chipIndex].player == sender) {
        currentRefundAmount += chips[chipIndex].amount;
        uint256 segmentIndex = chipIndex / _perSegmentSize;
        if (segmentIndex < segmentsCount) {
          segments[segmentIndex] -= chips[chipIndex].amount;
          previousRefundAmount += chips[chipIndex].amount;
        }
        delete chips[chipIndex];
      }
    }

    totalAmount -= currentRefundAmount;
    _previousAmount -= previousRefundAmount;
    return currentRefundAmount;
  }

  /**
   * pick a player to win punk
   */
  function _pick(uint256 randomness) internal view returns (address) {
    uint256 counter = 0;
    uint256 threshold = randomness % totalAmount;

    uint256 i = 0;
    for (; i < segmentsCount; i++) {
      if (counter + segments[i] > threshold) {
        break;
      }
      counter += segments[i];
    }
    for (uint256 j = i * _perSegmentSize; j < (i + 1) * _perSegmentSize; j++) {
      if (counter + chips[j].amount > threshold) {
        return chips[j].player;
      }
      counter += chips[j].amount;
    }

    return address(0);
  }

  /**
   * reset all states
   */
  function _reset() internal {
    delete chipsCount;
    delete segmentsCount;
    delete _previousAmount;
    delete totalAmount;
  }

  function _checkMaintainSegment(uint256 offset) internal view returns (bool) {
    return chipsCount > offset && ((chipsCount - offset) / _perSegmentSize > segmentsCount);
  }

  function _performMaintainSegment() internal {
    uint256 overflow;
    for (uint256 i = (chipsCount / _perSegmentSize) * _perSegmentSize; i < chipsCount; i++) {
      overflow += chips[i].amount;
    }
    segments[segmentsCount] = totalAmount - _previousAmount - overflow;
    segmentsCount += 1;
    _previousAmount = totalAmount;
  }
}

