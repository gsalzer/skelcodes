// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

contract Ownable {

  address public owner;
  address public transactionFee;
  address public buyBack;

  event OwnershipTransferred(address newOwner);
  event TransactionFeeTransferred(address newTransactionFee);
  event BuyBackTransferred(address newBuyBack);

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, 'You are not the owner!');
    _;
  }

  function transferOwnership(address newOwner) onlyOwner internal {
    owner = newOwner;
  }

  function transferTransactionFee(address newTransactionFee) onlyOwner internal {
    transactionFee = newTransactionFee;
  }

  function transferBuyBack(address newBuyBack) onlyOwner internal {
    buyBack = newBuyBack;
  }

}
