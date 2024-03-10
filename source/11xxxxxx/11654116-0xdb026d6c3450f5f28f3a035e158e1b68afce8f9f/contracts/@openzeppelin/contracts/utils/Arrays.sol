// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import '../math/Math.sol';

library Arrays {
  function findUpperBound(uint256[] storage array, uint256 element)
    internal
    view
    returns (uint256)
  {
    if (array.length == 0) {
      return 0;
    }

    uint256 low = 0;
    uint256 high = array.length;

    while (low < high) {
      uint256 mid = Math.average(low, high);

      if (array[mid] > element) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }

    if (low > 0 && array[low - 1] == element) {
      return low - 1;
    } else {
      return low;
    }
  }
}

