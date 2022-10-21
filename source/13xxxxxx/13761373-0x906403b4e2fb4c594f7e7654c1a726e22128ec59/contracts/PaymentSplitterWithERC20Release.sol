// SPDX-License-Identifier: MIT
/// @title: Payment Splitter Factory
/// @author: DropHero LLC
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PaymentSplitterWithERC20Transfer is Ownable, PaymentSplitter {
  constructor(
    address[] memory payees,
    uint256[] memory paymentShares
  ) PaymentSplitter(payees, paymentShares) {}

  function withdrawERC20(IERC20 tokenAddress, address to) external onlyOwner {
    tokenAddress.transfer(to, tokenAddress.balanceOf((address)(this)));
  }
}

