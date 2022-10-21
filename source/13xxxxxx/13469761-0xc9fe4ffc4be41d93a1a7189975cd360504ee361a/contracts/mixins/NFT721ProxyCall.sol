// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../interfaces/IProxyCall.sol";

/**
 * @notice Forwards arbitrary calls to an external contract to be processed.
 * @dev This is used so that the from address of the calling contract does not have
 * any special permissions (e.g. ERC-20 transfer).
 */
abstract contract NFT721ProxyCall {
  using AddressUpgradeable for address payable;

  IProxyCall private proxyCall;

  event ProxyCallContractUpdated(address indexed proxyCallContract);

  /**
   * @dev Called by the adminUpdateConfig function to set the address of the proxy call contract.
   */
  function _updateProxyCall(address proxyCallContract) internal {
    proxyCall = IProxyCall(proxyCallContract);

    emit ProxyCallContractUpdated(proxyCallContract);
  }

  /**
   * @notice Returns the address of the current proxy call contract.
   */
  function proxyCallAddress() external view returns (address) {
    return address(proxyCall);
  }

  /**
   * @dev Used by other mixins to make external calls through the proxy contract.
   * This will fail if the proxyCall address is address(0).
   */
  function _proxyCallAndReturnContractAddress(address externalContract, bytes memory callData)
    internal
    returns (address payable result)
  {
    result = proxyCall.proxyCallAndReturnAddress(externalContract, callData);
    require(result.isContract(), "NFT721ProxyCall: address returned is not a contract");
  }

  // This mixin uses a total of 100 slots
  uint256[99] private ______gap;
}

