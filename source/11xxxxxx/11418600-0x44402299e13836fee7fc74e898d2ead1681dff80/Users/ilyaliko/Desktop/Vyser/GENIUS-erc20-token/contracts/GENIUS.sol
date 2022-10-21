// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract GENIUS is ERC20 {
  using SafeMath for uint256;
  
  constructor(address receiver) ERC20("GENIUS", "GENI") public {
    ERC20._mint(receiver, uint256(9000000000).mul(10 ** ERC20.decimals()));
  }
}

