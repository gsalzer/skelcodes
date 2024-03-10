// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

import "./UniV2AdapterCore.sol";

contract UniV2ExcessWethCrossPair is UniV2AdapterCore {
  function tokenToTokenOutputAmount(
    IERC20 tokenIn,
    IERC20 tokenOut,
    uint tokenInAmount
  ) public view override returns (uint tokenOutAmount) {
    IERC20 wethToken = IERC20(address(weth));
    uint wethOut = _amountOut(tokenIn, wethToken, tokenInAmount);
    tokenOutAmount = _amountOut(wethToken, tokenOut, wethOut);
  }

  function tokenToTokenInputAmount(
    IERC20 tokenIn,
    IERC20 tokenOut,
    uint tokenOutAmount
  ) public view override returns (uint tokenInAmount) {
    IERC20 wethToken = IERC20(address(weth));
    uint wethIn = _amountIn(wethToken, tokenOut, tokenOutAmount);
    tokenInAmount = _amountIn(tokenIn, wethToken, wethIn);
  }

  function tokenToTokenExcess(IERC20 tokenIn, IERC20 tokenOut, uint tokenInAmount, uint tokenOutAmount)
    external view override
    returns (address[] memory excessTokens, int[] memory excessAmounts)
  {
    uint wethOut = _amountOut(tokenIn, IERC20(address(weth)), tokenInAmount);
    uint wethIn = _amountIn(IERC20(address(weth)), tokenOut, tokenOutAmount);
    excessTokens = new address[](1);
    excessTokens[0] = address(0);
    excessAmounts = new int[](1);
    excessAmounts[0] = int(wethOut - wethIn);
  }

  function ethToTokenExcess(IERC20 token, uint ethAmount, uint tokenAmount)
    external view override
    returns (address[] memory excessTokens, int[] memory excessAmounts)
  {
    excessTokens = new address[](1);
    excessTokens[0] = address(0);
    excessAmounts = new int[](1);
    excessAmounts[0] = int(ethAmount - _amountIn(IERC20(address(weth)), token, tokenAmount));
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
    IERC20 wethToken = IERC20(address(weth));
    uint wethOut = _amountOut(tokenIn, wethToken, tokenInAmount);
    uint wethIn = _amountIn(wethToken, tokenOut, tokenOutAmount);
    require(wethOut >= wethIn, 'UniV2ExcessWethCrossPair: tokenToToken INSUFFICIENT_INPUT_AMOUNT');
    _transferInputToPair(tokenIn, wethToken, tokenInAmount);
    _singlePairSwap(tokenIn, wethToken, tokenInAmount, wethOut, address(this));
    _transferInputToPair(wethToken, tokenOut, wethIn);
    _singlePairSwap(wethToken, tokenOut, wethIn, tokenOutAmount, account);
  }

  function ethToToken(IERC20 token, uint tokenAmount, address account) external payable override {
    IERC20 tokenIn = IERC20(address(weth));
    IERC20 tokenOut = token;
    uint swapInput = _amountIn(tokenIn, tokenOut, tokenAmount);
    require(msg.value >= swapInput, 'UniV2ExcessWethCrossPair: ethToToken INSUFFICIENT_INPUT_AMOUNT');
    weth.deposit{value: swapInput}();
    _transferInputToPair(tokenIn, tokenOut, swapInput);
    _singlePairSwap(tokenIn, tokenOut, swapInput, tokenAmount, account);
  }

  function tokenToEth(IERC20 token, uint tokenAmount, uint ethAmount, address account) external override {
    IERC20 tokenIn = token;
    IERC20 tokenOut = IERC20(address(weth));
    uint swapOutput = _amountOut(tokenIn, tokenOut, tokenAmount);
    require(swapOutput >= ethAmount, 'UniV2ExcessWethCrossPair: tokenToEth INSUFFICIENT_OUTPUT_AMOUNT');
    _transferInputToPair(tokenIn, tokenOut, tokenAmount);
    _singlePairSwap(tokenIn, tokenOut, tokenAmount, swapOutput, address(this));
    weth.withdraw(swapOutput);
    TransferHelper.safeTransferETH(account, ethAmount);
  }

  receive() external payable {}
}

