// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "ERC20.sol";
import "Ownable.sol";

contract KtlyoERC20 is ERC20, Ownable {
  constructor()
    Ownable()
    ERC20("Katalyo Token", "KTLYO")
    public {
    _mint(super.owner(), 85000000 * 10**uint(super.decimals()));
  }
}
