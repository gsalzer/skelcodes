// SPDX-License-Identifier: MIT
/// @title: Payment Splitter Factory
/// @author: DropHero LLC
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PaymentSplitterWithERC20Transfer is Ownable, PaymentSplitter {
  uint256 public lastVal = 0;
  constructor(
    address[] memory payees,
    uint256[] memory paymentShares
  ) PaymentSplitter(payees, paymentShares) {
    transferOwnership(payees[0]);
  }

  function emergencyWithdrawERC20(IERC20 tokenAddress) external {
    tokenAddress.transfer(owner(), tokenAddress.balanceOf((address)(this)));
  }
}

