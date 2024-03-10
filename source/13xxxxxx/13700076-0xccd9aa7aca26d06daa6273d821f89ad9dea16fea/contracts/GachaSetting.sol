// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

contract GachaSetting is Ownable {
  uint256 public serviceFeeThousandth = 100; // 10%

  uint256 public minimumBetValue = 0.01 ether;

  uint256 public maximumPunkValue = 200 ether;

  bool public isPaused = false;

  bytes32 internal _keyHash;

  uint256 internal _fee;

  function setServiceFeeThousandth(uint256 _serviceFeeThousandth) public onlyOwner {
    serviceFeeThousandth = _serviceFeeThousandth;
  }

  function setMinimumBetValue(uint256 _minimumBetValue) public onlyOwner {
    minimumBetValue = _minimumBetValue;
  }

  function setMaximumPunkValue(uint256 _maximumPunkValue) public onlyOwner {
    maximumPunkValue = _maximumPunkValue;
  }

  function setIsPaused(bool _isPaused) public onlyOwner {
    isPaused = _isPaused;
  }

  function setKeyHash(bytes32 keyHash) public onlyOwner {
    _keyHash = keyHash;
  }

  function setFee(uint256 fee) public onlyOwner {
    _fee = fee;
  }
}

