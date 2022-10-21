pragma solidity ^0.5.0 <0.6.0;

contract ReentrancyGuard {
  uint256 private _currentCounterState;

  constructor () public {
    _currentCounterState = 1;
  }

  modifier nonReentrant() {
    _currentCounterState++;
    uint256 originalCounterState = _currentCounterState;
    _;
    require(originalCounterState == _currentCounterState);
  }
}

