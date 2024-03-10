// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EPTT is ERC20Capped, Ownable {
  constructor(
    string memory name,
    string memory symbol,
    uint256 cap
  )
    ERC20Capped(cap)
    ERC20(name, symbol)
  { }

  function mint(address _to, uint256 _value) public onlyOwner {
    _mint(_to, _value);
  }
}
