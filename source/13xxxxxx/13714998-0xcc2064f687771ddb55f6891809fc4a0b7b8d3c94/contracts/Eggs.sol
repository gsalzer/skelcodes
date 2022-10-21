// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract Eggs is ERC20 {
  constructor() ERC20("EGG", "EGG") {
    _mint(msg.sender, 5000000 ether);
  }
}
