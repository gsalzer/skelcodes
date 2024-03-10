pragma solidity 0.5.8;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath64 {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint64 a, uint64 b) internal pure returns (uint64) {
    if (a == 0) {
      return 0;
    }
    uint64 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint64 a, uint64 b) internal pure returns (uint64) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint64 a, uint64 b) internal pure returns (uint64) {
    uint64 c = a + b;
    assert(c >= a);
    return c;
  }
}

