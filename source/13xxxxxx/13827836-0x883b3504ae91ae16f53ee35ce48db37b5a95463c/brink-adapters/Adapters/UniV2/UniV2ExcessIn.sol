// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

import "./UniV2AdapterCore.sol";

contract UniV2ExcessIn is UniV2AdapterCore {
  function tokenToTokenExcess(IERC20 tokenIn, IERC20 tokenOut, uint tokenInAmount, uint tokenOutAmount)
    external view override
    returns (address[] memory excessTokens, int[] memory excessAmounts)
  {
    excessTokens = new address[](1);
    excessTokens[0] = address(tokenIn);
    excessAmounts = new int[](1);
    excessAmounts[0] = int(tokenInAmount - _amountIn(tokenIn, tokenOut, tokenOutAmount));
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
    excessTokens[0] = address(token);
    excessAmounts = new int[](1);
    excessAmounts[0] = int(tokenAmount - _amountIn(token, IERC20(address(weth)), ethAmount));
  }

  function tokenToToken(IERC20 tokenIn, IERC20 tokenOut, uint tokenInAmount, uint tokenOutAmount, address account) external override {
    uint swapInput = _amountIn(tokenIn, tokenOut, tokenOutAmount);
    require(tokenInAmount >= swapInput, 'UniV2ExcessIn: tokenToToken INSUFFICIENT_INPUT_AMOUNT');
    _transferInputToPair(tokenIn, tokenOut, swapInput);
    _singlePairSwap(tokenIn, tokenOut, swapInput, tokenOutAmount, account);
  }

  function ethToToken(IERC20 token, uint tokenAmount, address account) external payable override {
    IERC20 tokenIn = IERC20(address(weth));
    IERC20 tokenOut = token;
    uint swapInput = _amountIn(tokenIn, tokenOut, tokenAmount);
    require(msg.value >= swapInput, 'UniV2ExcessIn: ethToToken INSUFFICIENT_INPUT_AMOUNT');
    weth.deposit{value: swapInput}();
    _transferInputToPair(tokenIn, tokenOut, swapInput);
    _singlePairSwap(tokenIn, tokenOut, swapInput, tokenAmount, account);
  }

  function tokenToEth(IERC20 token, uint tokenAmount, uint ethAmount, address account) external override {
    IERC20 tokenIn = token;
    IERC20 tokenOut = IERC20(address(weth));
    uint swapInput = _amountIn(tokenIn, tokenOut, ethAmount);
    require(tokenAmount >= swapInput, 'UniV2ExcessIn: tokenToEth INSUFFICIENT_INPUT_AMOUNT');
    _transferInputToPair(tokenIn, tokenOut, swapInput);
    _singlePairSwap(tokenIn, tokenOut, swapInput, ethAmount, address(this));
    weth.withdraw(ethAmount);
    TransferHelper.safeTransferETH(account, ethAmount);
  }

  receive() external payable {}
}

