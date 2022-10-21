// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../vendor/AccessControllerInterface.sol";

interface AccessControlledInterface {
  event AccessControllerSet(
    address indexed accessController,
    address indexed sender
  );

  function setAccessController(
    AccessControllerInterface _accessController
  )
    external;

  function getAccessController()
    external
    view
    returns (
      AccessControllerInterface
    );
}

