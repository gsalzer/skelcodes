pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import { PreprocessorLib } from "./lib/PreprocessorLib.sol";
import { IUniswapExchange } from "../interfaces/IUniswapExchange.sol";
import { IUniswapFactory } from "../interfaces/IUniswapFactory.sol";
import { ShifterBorrowProxyLib } from "../ShifterBorrowProxyLib.sol";
import { SandboxLib } from "../utils/sandbox/SandboxLib.sol";
import { BorrowProxyLib } from "../BorrowProxyLib.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { StringLib } from "../utils/StringLib.sol";

contract SwapEntireLoan {
  using PreprocessorLib for *;
  using StringLib for *;
  BorrowProxyLib.ProxyIsolate isolate;
  address public factory;
  address public target;
  function setup(bytes memory consData) public {
    (factory, target) = abi.decode(consData, (address, address));
  }
  function execute(bytes memory data) view public returns (ShifterBorrowProxyLib.InitializationAction[] memory result) {
    SandboxLib.ExecutionContext memory context = data.toContext();
    result = IUniswapFactory(SwapEntireLoan(context.preprocessorAddress).factory())
      .getExchange(isolate.token)
      .sendTransaction(abi.encodeWithSelector(
        IUniswapExchange.tokenToTokenSwapInput.selector,
        IERC20(isolate.token).balanceOf(address(this)),
        1,
        1,
        block.timestamp + 1,
        SwapEntireLoan(context.preprocessorAddress).target()));
  }
}

