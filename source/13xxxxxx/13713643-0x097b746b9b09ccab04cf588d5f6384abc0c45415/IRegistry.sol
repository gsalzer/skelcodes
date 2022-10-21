// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IRegistry {
  event SystemWalletUpdated(address newWallet);
  event FeeVariablesChanged(uint256 indexed newFee, uint256 indexed newScale);
  event ContractStatusChanged(address indexed changed, bool indexed status);
  event CurrencyStatusChanged(address indexed changed, bool indexed status);

  function feeInfo(uint256 _salePrice) external view returns(address, uint256);
  function isPlatformContract(address toCheck) external view returns(bool);
  function isApprovedCurrency(address tokenContract) external view returns(bool);
  function setSystemWallet(address newWallet) external;
  function setFeeVariables(uint256 newFee, uint256 newScale) external;
  function setContractStatus(address toChange, bool status) external;
  function setCurrencyStatus(address tokenContract, bool status) external;
  function approveAllCurrencies() external;
}
