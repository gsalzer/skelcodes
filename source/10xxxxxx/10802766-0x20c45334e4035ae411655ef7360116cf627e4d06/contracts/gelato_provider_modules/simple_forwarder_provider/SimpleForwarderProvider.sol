// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {GelatoProviderModuleStandard} from "../GelatoProviderModuleStandard.sol";
import {
    Action, Operation, DataFlow, Task
} from "../../gelato_core/interfaces/IGelatoCore.sol";
import {
    IGelatoUserProxyFactory
} from "../../user_proxies/gelato_user_proxy/interfaces/IGelatoUserProxyFactory.sol";
import {
    IGelatoUserProxy
} from "../../user_proxies/gelato_user_proxy/interfaces/IGelatoUserProxy.sol";
import {GelatoActionPipeline} from "../../gelato_actions/GelatoActionPipeline.sol";

/// @title PanDaoProviderModule
/// @author Hilmar X
/// @notice Used to a) make sure only InsurancePools can execute Tx's and have PanDAOs GelatoManager pay for it
/// b) Channels the encoded Payload from each Insurance Pool contract to GelatoCore
contract SimpleForwarderProvider is GelatoProviderModuleStandard {

  constructor() public {}

  // Verify that the address requesting execution is a PanDAO Insurance Pool
  function isProvided(
    address,
    address,
    Task calldata
  ) external override view returns (string memory isOk) {
    return string("OK");
  }

  // Function called by gelato core before execution
  function execPayload(
    uint256,
    address,
    address,
    Task calldata _task,
    uint256
  ) external virtual override view returns (bytes memory, bool) {
    return (_task.actions[0].data, false);
  }
}
