// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import '../../utils/Console.sol';
import '../../pool/BaseHelper.sol';

contract CurveHelper is BaseHelper {
  using Address for address;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  function swap(string memory /* path */, uint256 /* amount */, uint256 /* min */, address /* dest */) override external returns (uint256 swapped) {
    swapped = 0;
  }

}

