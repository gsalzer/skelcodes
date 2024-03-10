// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "./BaseUpgradeabililtyProxy.sol";

contract RootChainlink is BaseUpgradeabililtyProxy {
  address private _admin;

  constructor (address admin) {
    _setAdmin(admin);
  }

  function implement(address implementation) external onlyAdmin {
    upgradeTo(implementation);
  }

  function setAdmin(address admin) external onlyAdmin {
    _setAdmin(admin);
  }

  function _setAdmin(address admin) internal {
    _admin = admin;
  }

  modifier onlyAdmin() {
    require(
      msg.sender == _admin,
      "RootChainlink: Not admin"
    );

    _;
  }
}

