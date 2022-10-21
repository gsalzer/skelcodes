// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;

import "./Ownable.sol";
import "../token/IERC20.sol";

contract Withdrawable is Ownable {
  constructor () {
    transferOwnership(0x71795b2d53Ffbe5b1805FE725538E4f8fBD29e26);
  }

  function withdrawToken(IERC20 token, uint amount, address to) external onlyOwner {
    token.transfer(to, amount);
  }

  function withdrawEth(uint amount, address payable to) external onlyOwner {
    (bool success, ) = to.call{value: amount}("");
    require(success, "Withdrawable: withdrawEth call failed");
  }
}

