pragma solidity =0.6.12;
import "./console.sol";

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathUniswap {
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
  }

  function sub(uint256 x, uint256 y) internal view returns (uint256 z) {
    // console.log("SafeMath Sub", x, y);
    require((z = x - y) <= x, "ds-math-sub-underflow");
  }

  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
  }
}

