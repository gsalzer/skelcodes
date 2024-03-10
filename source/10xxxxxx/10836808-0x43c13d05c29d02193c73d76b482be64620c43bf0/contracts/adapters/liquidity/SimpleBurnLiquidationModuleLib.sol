pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import { AddressSetLib } from "../../utils/AddressSetLib.sol";
import { BorrowProxyLib } from "../../BorrowProxyLib.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { TokenUtils } from "../../utils/TokenUtils.sol";
import { ModuleLib } from "../lib/ModuleLib.sol";
import { SimpleBurnLiquidationModule } from "./SimpleBurnLiquidationModule.sol";

library SimpleBurnLiquidationModuleLib {
  struct Isolate {
    address routerAddress;
    address erc20Module;
    uint256 liquidated;
    AddressSetLib.AddressSet toLiquidate;
  }
  struct ExternalIsolate {
    address routerAddress;
    address erc20Module;
  }
  function computeIsolatePointer() public pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked("isolate.simple-burn")));
  }
  function getCastStorageType() internal pure returns (function (uint256) internal pure returns (Isolate storage) swap) {
    function (uint256) internal returns (uint256) cast = ModuleLib.cast;
    assembly {
      swap := cast
    }
  }
  function toIsolatePointer(uint256 key) internal pure returns (Isolate storage) {
    return getCastStorageType()(key);
  }
  function getIsolatePointer() internal pure returns (Isolate storage) {
    return toIsolatePointer(computeIsolatePointer());
  }
}

