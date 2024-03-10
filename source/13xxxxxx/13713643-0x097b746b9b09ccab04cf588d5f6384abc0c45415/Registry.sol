// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * @title Registry for the Etched platform
 * @author Linum Labs
 */

import "./Ownable.sol";
import "./IRegistry.sol";

contract EtchedRegistry is IRegistry, Ownable {
  mapping(address => bool) private platformContracts;
  mapping(address => bool) private approvedCurrencies;
  bool allowAllCurrencies;
  address systemWallet;
  // scale: how many zeroes should follow the fee
  // in the default values, there would be a 10% tax on a 18 decimal asset
  uint256 fee = 10_000;
  uint256 scale = 1e5;

  constructor() {
    approvedCurrencies[address(0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa)] = true;
  }

  /// @notice checks if a contract is active on the platform
  /// @dev used by platform contracts to verify interactions
  /// @param toCheck the address of the contract to check
  /// @return a boolean if the contract is active on the platform or not
  function isPlatformContract(address toCheck) external view override returns(bool) {
    return platformContracts[toCheck];
  }

  /// @notice checks if a token is approved for use on the platform
  /// @dev use 0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa for ETH
  /// @param tokenContract the address of the token to check
  /// @return a boolean value if the token is approved for use on the platform
  function isApprovedCurrency(address tokenContract) external view override returns(bool) {
    if(allowAllCurrencies) return true;
    return approvedCurrencies[tokenContract];
  }

  /// @notice returns relevant details about system fees
  /// @dev structured similar to EIP2981 for royalties
  /// @param _salePrice the amount of a sale to calculate fees for
  /// @return a tuple of (address, uint256) of the system wallet and the amount of the fee
  function feeInfo(uint256 _salePrice) external view override returns(address, uint256) {
    return (systemWallet, (_salePrice * fee / scale));
  }

  /// @notice sets the address for the system wallet
  /// @param newWallet the address of the new system wallet
  function setSystemWallet(address newWallet) external override onlyOwner {
    systemWallet = newWallet;

    emit SystemWalletUpdated(newWallet);
  }

  /// @notice sets the global fee variables (fee and scale)
  /// @dev fee / scale = percentage
  /// @param newFee the new value for the fee global variable
  /// @param newScale the new value for the scale global variable
  function setFeeVariables(uint256 newFee, uint256 newScale) external override onlyOwner {
    fee = newFee;
    scale = newScale;
    emit FeeVariablesChanged(newFee, newScale);
  }

  /// @notice sets the status of a contract as active or inactive
  /// @param toChange the address of the contract to change the status of
  /// @param status a bool representing if the contract should be active or not
  function setContractStatus(address toChange, bool status) external override onlyOwner {
    string memory boolString = status == true ? "true" : "false";
    require(platformContracts[toChange] != status, 
      string(abi.encodePacked("contract status is already ", boolString))
    );
    platformContracts[toChange] = status;
    emit ContractStatusChanged(toChange, status);
  }

  /// @notice Explain to an end user what this does
  /// @dev Explain to a developer any extra details
  /// @param tokenContract the address of the token to change the status of
  /// @param status a bool representing if the token is approved or not
  function setCurrencyStatus(address tokenContract, bool status) external override onlyOwner {
    require(!allowAllCurrencies, "all currencies approved");
    string memory boolString = status == true ? "true" : "false";
    require(approvedCurrencies[tokenContract] != status, 
      string(abi.encodePacked("token status is already ", boolString))
    );
    approvedCurrencies[tokenContract] = status;
    emit CurrencyStatusChanged(tokenContract, status);
  }

  /// @notice globally allows all tokens
  /// @dev this is irrversible, and can only be called once
  function approveAllCurrencies() external override onlyOwner {
    require(!allowAllCurrencies, "already approved");
    allowAllCurrencies = true;
    emit CurrencyStatusChanged(address(0), true);
  }
}

