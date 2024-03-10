// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**

   8 888888888o.      ,o888888o.        ,o888888o.
   8 8888    `88.    8888     `88.     8888     `88.
   8 8888     `88 ,8 8888       `8. ,8 8888       `8.
   8 8888     ,88 88 8888           88 8888
   8 8888.   ,88' 88 8888           88 8888
   8 888888888P'  88 8888           88 8888
   8 8888`8b      88 8888           88 8888
   8 8888 `8b.    `8 8888       .8' `8 8888       .8'
   8 8888   `8b.     8888     ,88'     8888     ,88'
   8 8888     `88.    `8888888P'        `8888888P'

*/

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CollectiveSplitter is PaymentSplitter, Ownable {
  address[] private _payees;

  constructor(address[] memory payees, uint256[] memory shares_) PaymentSplitter(payees, shares_) {
    _payees = payees;
  }

  function flush() public onlyOwner {
    for (uint256 i = 0; i < _payees.length; i++) {
      address addr = _payees[i];
      release(payable(addr));
    }
  }
}

