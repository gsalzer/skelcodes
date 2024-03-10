/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '@openzeppelin/contracts/proxy/UpgradeableProxy.sol';
import '@openzeppelin/contracts/utils/Context.sol';

import '../utils/AddressBook.sol';
import '../utils/interfaces/IAddressRegistry.sol';

contract UpgradeProxy is Context, UpgradeableProxy {
  /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 private constant _ADMIN_SLOT =
    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  /**
   * @dev Emitted when the admin account has changed.
   */
  event AdminChanged(address previousAdmin, address newAdmin);

  /**
   * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
   */
  modifier ifAdmin() {
    if (_msgSender() == _admin()) {
      _;
    } else {
      _fallback();
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  constructor(
    IAddressRegistry addressRegistry_,
    address _logic,
    bytes memory _data
  ) UpgradeableProxy(_logic, _data) {
    assert(
      _ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
    );
    // Initialize {AccessControl}
    address marketingWallet = addressRegistry_.getRegistryEntry(
      AddressBook.MARKETING_WALLET
    );
    _setAdmin(marketingWallet);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Upgrade the implementation of the proxy.
   *
   * NOTE: Only the admin can call this function.
   */
  function upgradeTo(address newImplementation) external virtual ifAdmin {
    _upgradeTo(newImplementation);
  }

  /**
   * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
   * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
   * proxied contract.
   *
   * NOTE: Only the admin can call this function.
   */
  function upgradeToAndCall(address newImplementation, bytes calldata data)
    external
    virtual
    ifAdmin
  {
    _upgradeTo(newImplementation);
    Address.functionDelegateCall(newImplementation, data);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Internal
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Returns the current admin.
   */
  function _admin() internal view virtual returns (address adm) {
    bytes32 slot = _ADMIN_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      adm := sload(slot)
    }
  }

  /**
   * @dev Stores a new address in the EIP1967 admin slot.
   */
  function _setAdmin(address adm) private {
    bytes32 slot = _ADMIN_SLOT;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, adm)
    }
  }
}

