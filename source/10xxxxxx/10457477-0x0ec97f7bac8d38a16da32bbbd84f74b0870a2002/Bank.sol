// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.6.8;

import "./SafeMath.sol";

contract Bank {
  struct Account {
    uint amount;
    uint received;
    uint percentage;
    bool exists;
  }

  uint internal constant ENTRY_ENABLED = 1;
  uint internal constant ENTRY_DISABLED = 2;

  mapping(address => Account) internal accountStorage;
  mapping(uint => address) internal accountLookup;
  mapping(uint => uint) internal agreementAmount;
  uint internal reentry_status;
  uint internal totalHolders;
  uint internal systemBalance = 0;

  using SafeMath for uint;

  modifier hasAccount(address _account) {
      require(accountStorage[_account].exists, "Bank account dont exist!");
      _;
    }

  modifier blockReEntry() {      
    require(reentry_status != ENTRY_DISABLED, "Security Block");
    reentry_status = ENTRY_DISABLED;

    _;

    reentry_status = ENTRY_ENABLED;
  }

  function initiateDistribute() external hasAccount(msg.sender) {
    uint amount = distribute(systemBalance);

    systemBalance = systemBalance.sub(amount);
  }

  function distribute(uint _amount) internal returns (uint) {
    require(_amount > 0, "No amount transferred");

    uint percentage = _amount.div(100);
    uint total_used = 0;
    uint pay = 0;

    for (uint num = 0; num < totalHolders;num++) {
      pay = percentage * accountStorage[accountLookup[num]].percentage;

      if (pay > 0) {
        if (total_used.add(pay) > _amount) { //Ensure we do not pay out too much
          pay = _amount.sub(total_used);
        }

        deposit(accountLookup[num], pay);
        total_used = total_used.add(pay);
      }

      if (total_used >= _amount) { //Ensure we stop if we have paid out everything
        break;
      }
    }

    return total_used;
  }

  function deposit(address _to, uint _amount) internal hasAccount(_to) {
    accountStorage[_to].amount = accountStorage[_to].amount.add(_amount);
  }

  receive() external payable blockReEntry() {
    systemBalance = systemBalance.add(msg.value);
  }

  function getSystemBalance() external view hasAccount(msg.sender) returns (uint) {
    return systemBalance;
  }

  function getBalance() external view hasAccount(msg.sender) returns (uint) {
    return accountStorage[msg.sender].amount;
  }

  function getReceived() external view hasAccount(msg.sender) returns (uint) {
    return accountStorage[msg.sender].received;
  }
  
  function withdraw(uint _amount) external payable hasAccount(msg.sender) blockReEntry() {
    require(accountStorage[msg.sender].amount >= _amount && _amount > 0, "Not enough funds");

    accountStorage[msg.sender].amount = accountStorage[msg.sender].amount.sub(_amount);
    accountStorage[msg.sender].received = accountStorage[msg.sender].received.add(_amount);

    (bool success, ) = msg.sender.call{ value: _amount }("");
    
    require(success, "Transfer failed");
  }

  function withdrawTo(address payable _to, uint _amount) external hasAccount(msg.sender) blockReEntry() {
    require(accountStorage[msg.sender].amount >= _amount && _amount > 0, "Not enough funds");

    accountStorage[msg.sender].amount = accountStorage[msg.sender].amount.sub(_amount);
    accountStorage[msg.sender].received = accountStorage[msg.sender].received.add(_amount);

    (bool success, ) = _to.call{ value: _amount }("");
    
    require(success, "Transfer failed");
  }

  function subPercentage(address _addr, uint _percentage) internal hasAccount(_addr) {
      accountStorage[_addr].percentage = accountStorage[_addr].percentage.sub(_percentage);
    }

  function addPercentage(address _addr, uint _percentage) internal hasAccount(_addr) {
      accountStorage[_addr].percentage = accountStorage[_addr].percentage.add(_percentage);
    }

  function getPercentage() external view hasAccount(msg.sender) returns (uint) {
    return accountStorage[msg.sender].percentage;
  }

  function validateBalance() external hasAccount(msg.sender) returns (uint) { //Allow any account to verify/adjust contract balance
    uint amount = systemBalance;

    for (uint num = 0; num < totalHolders;num++) {
      amount = amount.add(accountStorage[accountLookup[num]].amount);
    }

    if (amount < address(this).balance) {
      uint balance = address(this).balance;
      balance = balance.sub(amount);

      systemBalance = systemBalance.add(balance);

      return balance;
    }

    return 0;
  }

  function createAccount(address _addr, uint _amount, uint _percentage, uint _agreementAmount) internal {
    accountStorage[_addr] = Account({amount: _amount, received: 0, percentage: _percentage, exists: true});
    agreementAmount[totalHolders] = _agreementAmount;
    accountLookup[totalHolders++] = _addr;
  }

  function deleteAccount(address _addr, address _to) internal hasAccount(_addr) {
    deposit(_to, accountStorage[_addr].amount);

    for (uint8 num = 0; num < totalHolders;num++) {
      if (accountLookup[num] == _addr) {
        delete(accountLookup[num]);
        break;
      }
    }

    delete(accountStorage[_addr]);
    totalHolders--;
  }
}
