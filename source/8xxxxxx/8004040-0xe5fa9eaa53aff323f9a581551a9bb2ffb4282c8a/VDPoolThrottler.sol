pragma solidity ^0.5.8;


contract VDPoolThrottler {
    function getCooldownBlocks() external view returns(uint256);
}

contract DummyThrottler is VDPoolThrottler {
    function getCooldownBlocks() external view returns(uint256) {
      return 1;
  }
}

