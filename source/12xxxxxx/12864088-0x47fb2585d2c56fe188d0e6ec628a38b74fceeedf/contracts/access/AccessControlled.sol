// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@chainlink/contracts/src/v0.7/dev/ConfirmedOwner.sol";
import "../interfaces/AccessControlledInterface.sol";
import "../interfaces/AccessControllerInterface.sol";

contract AccessControlled is AccessControlledInterface, ConfirmedOwner(msg.sender) {
  AccessControllerInterface internal s_accessController;

  function setAccessController(
    AccessControllerInterface _accessController
  )
    public
    override
    onlyOwner()
  {
    require(address(_accessController) != address(s_accessController), "Access controller is already set");
    s_accessController = _accessController;
    emit AccessControllerSet(address(_accessController), msg.sender);
  }

  function getAccessController()
    public
    view
    override
    returns (
      AccessControllerInterface
    )
  {
    return s_accessController;
  }
}

