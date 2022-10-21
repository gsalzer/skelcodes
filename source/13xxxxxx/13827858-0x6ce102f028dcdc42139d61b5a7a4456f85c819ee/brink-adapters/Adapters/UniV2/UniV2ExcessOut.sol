// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

import "./UniV2AdapterCore.sol";

contract UniV2ExcessOut is UniV2AdapterCore {
  function tokenToTokenExcess(IERC20 tokenIn, IERC20 tokenOut, uint tokenInAmount, uint tokenOutAmount)
    external view override
    returns (address[] memory excessTokens, int[] memory excessAmounts)
  {
    excessTokens = new address[](1);
    excessTokens[0] = address(tokenOut);
    excessAmounts = new int[](1);
    excessAmounts[0] = int(_amountOut(tokenIn, tokenOut, tokenInAmount) - tokenOutAmount);
  }

  function ethToTokenExcess(IERC20 token, uint ethAmount, uint tokenAmount)
    external view override
    returns (address[] memory excessTokens, int[] memory excessAmounts)
  {
    excessTokens = new address[](1);
    excessTokens[0] = address(token);
    excessAmounts = new int[](1);
    excessAmounts[0] = int(_amountOut(IERC20(address(weth)), token, ethAmount) - tokenAmount);
  }

  function tokenToEthExcess(IERC20 token, uint tokenAmount, uint ethAmount)
    external view override
    returns (address[] memory excessTokens, int[] memory excessAmounts)
  {
    excessTokens = new address[](1);
    excessTokens[0] = address(0);
    excessAmounts = new int[](1);
    excessAmounts[0] = int(_amountOut(token, IERC20(address(weth)), tokenAmount) - ethAmount);
  }

  function tokenToToken(IERC20 tokenIn, IERC20 tokenOut, uint tokenInAmount, uint tokenOutAmount, address account) external override {
    uint swapOutput = _amountOut(tokenIn, tokenOut, tokenInAmount);
    require(swapOutput >= tokenOutAmount, 'UniV2ExcessOut: tokenToToken INSUFFICIENT_OUTPUT_AMOUNT');
    _transferInputToPair(tokenIn, tokenOut, tokenInAmount);
    _singlePairSwap(tokenIn, tokenOut, tokenInAmount, swapOutput, address(this));
    TransferHelper.safeTransfer(address(tokenOut), account, tokenOutAmount);
  }

  function ethToToken(IERC20 token, uint tokenAmount, address account) external payable override {
    IERC20 tokenIn = IERC20(address(weth));
    IERC20 tokenOut = token;
    uint swapOutput = _amountOut(tokenIn, tokenOut, msg.value);
    require(swapOutput >= tokenAmount, 'UniV2ExcessOut: ethToToken INSUFFICIENT_OUTPUT_AMOUNT');
    weth.deposit{value: msg.value}();
    _transferInputToPair(tokenIn, tokenOut, msg.value);
    _singlePairSwap(tokenIn, tokenOut, msg.value, swapOutput, address(this));
    TransferHelper.safeTransfer(address(tokenOut), account, tokenAmount);
  }

  function tokenToEth(IERC20 token, uint tokenAmount, uint ethAmount, address account) external override {
    IERC20 tokenIn = token;
    IERC20 tokenOut = IERC20(address(weth));
    uint swapOutput = _amountOut(tokenIn, tokenOut, tokenAmount);
    require(swapOutput >= ethAmount, 'UniV2ExcessOut: tokenToEth INSUFFICIENT_OUTPUT_AMOUNT');
    _transferInputToPair(tokenIn, tokenOut, tokenAmount);
    _singlePairSwap(tokenIn, tokenOut, tokenAmount, swapOutput, address(this));
    weth.withdraw(swapOutput);
    TransferHelper.safeTransferETH(account, ethAmount);
  }

  receive() external payable {}
}

