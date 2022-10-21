pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import { PreprocessorLib } from "./lib/PreprocessorLib.sol";
import { ShifterBorrowProxyLib } from "../ShifterBorrowProxyLib.sol";
import { SandboxLib } from "../utils/sandbox/SandboxLib.sol";
import { BorrowProxyLib } from "../BorrowProxyLib.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { StringLib } from "../utils/StringLib.sol";
import { IUniswapV2Router01 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import { IUniswapV2Pair } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import { UniswapV2AdapterLib } from "../adapters/assets/uniswap-v2/UniswapV2AdapterLib.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

contract V2SwapAndDrop {
  using SafeMath for uint256;
  using UniswapV2AdapterLib for *;
  using PreprocessorLib for *;
  BorrowProxyLib.ProxyIsolate isolate;
  address public router;
  address public token;
  address public recipient;
  function setup(bytes memory consData) public {
    (router, token, recipient) = abi.decode(consData, (address, address, address));
  }
  function execute(bytes memory data) view public returns (ShifterBorrowProxyLib.InitializationAction[] memory result) {
    SandboxLib.ExecutionContext memory context = data.toContext();
    V2SwapAndDrop self = V2SwapAndDrop(context.preprocessorAddress);
    IUniswapV2Router01 selfRouter = IUniswapV2Router01(self.router());
    address borrowToken = isolate.token;
    address[] memory path = UniswapV2AdapterLib.generatePathForToken(borrowToken, selfRouter.WETH(), self.token());
    return address(selfRouter).sendTransaction(UniswapV2AdapterLib.SwapExactTokensForTokensInputs({
      amountIn: IERC20(borrowToken).balanceOf(address(this)),
      amountOutMin: 1,
      path: path,
      to: self.recipient(),
      deadline: block.timestamp + 1
    }).encodeWithSelector());
  }
}

