pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import { PreprocessorLib } from "./lib/PreprocessorLib.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ShifterBorrowProxyLib } from "../ShifterBorrowProxyLib.sol";
import { SandboxLib } from "../utils/sandbox/SandboxLib.sol";
import { BorrowProxyLib } from "../BorrowProxyLib.sol";

contract TransferAll {
  using PreprocessorLib for *;
  BorrowProxyLib.ProxyIsolate isolate;
  address public target;
  function setup(bytes memory consData) public {
    (target) = abi.decode(consData, (address));
  }
  function execute(bytes memory data) view public returns (ShifterBorrowProxyLib.InitializationAction[] memory) {
    SandboxLib.ExecutionContext memory context = data.toContext();
    address token = isolate.token;
    return isolate.token.sendTransaction(abi.encodeWithSelector(IERC20.transfer.selector, TransferAll(context.preprocessorAddress).target(), IERC20(token).balanceOf(address(this))));
  }
}

