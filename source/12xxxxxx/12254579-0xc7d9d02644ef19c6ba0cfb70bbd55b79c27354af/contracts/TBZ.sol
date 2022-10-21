// contracts/ExampleToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TBZ is ERC20Burnable, Ownable {
  constructor () ERC20("Tabzcoin", "TBZ") {
    _mint(
      msg.sender,
      2000000000 * (10**uint256(decimals()))
    );
  }
}
