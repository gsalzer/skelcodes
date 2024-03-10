// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

contract Ownable {

  address public owner;
  address public feeAddress;
  address public reserveAddress;

  event OwnershipTransferred(address newOwner);
  event FeeAddressTransferred(address newFeeAddress);
  event ReserveAddressTransferred(address newReserveAddress);

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

  function transferFeeAddress(address newFeeAddress) onlyOwner internal {
    feeAddress = newFeeAddress;
  }

  function transferReserveAddress(address newReserveAddress) onlyOwner internal {
    reserveAddress = newReserveAddress;
  }

}
